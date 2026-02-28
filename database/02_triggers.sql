/*  1) Order_Item değişince Orders.total_qty / total_price güncelle */
CREATE OR ALTER TRIGGER trg_UpdateOrderTotal
ON Order_Item
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ChangedOrders AS (
        SELECT order_id FROM inserted
        UNION
        SELECT order_id FROM deleted
    ),
    Totals AS (
        SELECT
            oi.order_id,
            SUM(oi.quantity) AS total_qty,
            CAST(SUM(oi.sub_total) AS DECIMAL(10,2)) AS total_price
        FROM Order_Item oi
        JOIN ChangedOrders c ON c.order_id = oi.order_id
        GROUP BY oi.order_id
    )
    UPDATE o
    SET
        o.total_qty   = ISNULL(t.total_qty, 0),
        o.total_price = ISNULL(t.total_price, 0)
    FROM Orders o
    JOIN ChangedOrders c ON c.order_id = o.order_id
    LEFT JOIN Totals t ON t.order_id = o.order_id;
END;
GO


/*   2) Review değişince Seller.store_rating güncelle */
CREATE TRIGGER trg_UpdateStoreRating
ON Review
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH AffectedSellers AS (
        SELECT DISTINCT p.seller_id
        FROM Products p
        JOIN inserted i ON i.product_id = p.product_id

        UNION

        SELECT DISTINCT p.seller_id
        FROM Products p
        JOIN deleted d ON d.product_id = p.product_id
    )
    UPDATE s
    SET s.store_rating = ISNULL((
            SELECT CAST(AVG(CAST(r.rating AS DECIMAL(10,2))) AS DECIMAL(3,2))
            FROM Review r
            JOIN Products p2 ON p2.product_id = r.product_id
            WHERE p2.seller_id = s.seller_id
        ), 0)
    FROM Seller s
    JOIN AffectedSellers a ON a.seller_id = s.seller_id;
END;
GO


/*  3) Orders INSERT olurken: o cart için en son ödeme Success değilse Order oluşmasın*/
CREATE TRIGGER trg_Orders_RequireLatestPaymentSuccess
ON Orders
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        OUTER APPLY (
            SELECT TOP (1) p.payment_status
            FROM Payment p
            WHERE p.cart_id = i.cart_id
            ORDER BY p.attempt_number DESC
        ) lastp
        WHERE ISNULL(lastp.payment_status,'') <> 'Success'
    )
    BEGIN
        RAISERROR('Order cannot be created: latest payment attempt is not Success for this cart.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO


/* 4) Order_Item değişince Products.stock_quantity güncelle  (stok negatif olamaz) */
CREATE OR ALTER TRIGGER trg_ProductStock_OnOrderItemChange
ON dbo.Order_Item
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Delta TABLE (
        product_id INT PRIMARY KEY,
        net_delta_qty INT NOT NULL
    );

    INSERT INTO @Delta(product_id, net_delta_qty)
    SELECT
        x.product_id,
        SUM(x.delta_qty) AS net_delta_qty
    FROM (
        SELECT i.product_id, CAST(i.quantity AS INT) AS delta_qty
        FROM inserted i

        UNION ALL

        SELECT d.product_id, -CAST(d.quantity AS INT) AS delta_qty
        FROM deleted d
    ) x
    GROUP BY x.product_id;

    -- stok negatife düşecek mi kontrol
    IF EXISTS (
        SELECT 1
        FROM dbo.Products p
        JOIN @Delta d ON d.product_id = p.product_id
        WHERE p.stock_quantity - d.net_delta_qty < 0
    )
    BEGIN
        RAISERROR('Insufficient stock: Order_Item change would make stock negative.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- stok güncelle
    UPDATE p
    SET p.stock_quantity = p.stock_quantity - d.net_delta_qty
    FROM dbo.Products p
    JOIN @Delta d ON d.product_id = p.product_id
    WHERE d.net_delta_qty <> 0;
END;
GO


/*  5) Shipment status Cancelled yapılınca stok iadesi */
CREATE OR ALTER TRIGGER trg_ProductStock_OnShipmentCancelled
ON Shipment
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(status) RETURN;

    ;WITH StatusChange AS (
        SELECT
            i.order_id,
            d.status AS old_status,
            i.status AS new_status
        FROM inserted i
        JOIN deleted  d ON d.order_id = i.order_id
        WHERE ISNULL(d.status,'') <> ISNULL(i.status,'')
    ),
    CancelledNow AS (
        SELECT sc.order_id
        FROM StatusChange sc
        WHERE sc.old_status <> 'Cancelled'
          AND sc.new_status = 'Cancelled'
    ),
    QtyByProduct AS (
        SELECT oi.product_id, SUM(oi.quantity) AS qty
        FROM Order_Item oi
        JOIN CancelledNow c ON c.order_id = oi.order_id
        GROUP BY oi.product_id
    )
    UPDATE p
    SET p.stock_quantity = p.stock_quantity + q.qty
    FROM Products p
    JOIN QtyByProduct q ON q.product_id = p.product_id;
END;
GO
