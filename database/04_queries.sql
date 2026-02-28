USE [Amazon];
GO
  
SELECT country, COUNT(*) AS buyer_cnt
FROM Buyer
GROUP BY country
ORDER BY buyer_cnt DESC, country;

SELECT TOP 20 country, city, gender, COUNT(*) AS buyer_cnt
FROM dbo.Buyer
GROUP BY country, city, gender
ORDER BY buyer_cnt DESC;

SELECT
  CASE WHEN LOWER(b.country) IN ('turkiye','türkiye','turkey')
       THEN 'domestic' ELSE 'international' END AS order_type,
  COUNT(*) AS total_order
FROM Orders o
JOIN Cart  c ON c.cart_id = o.cart_id
JOIN Buyer b ON b.buyer_id = c.buyer_id
GROUP BY
  CASE WHEN LOWER(b.country) IN ('turkiye','türkiye','turkey')
       THEN 'domestic' ELSE 'international' END;


--Ülkeye göre sipariş sayısı + toplam ciro
SELECT b.country,
       COUNT(DISTINCT o.order_id) AS order_cnt,
       CAST(SUM(o.total_price) AS DECIMAL(12,2)) AS revenue
FROM dbo.Orders o
JOIN dbo.Cart c ON c.cart_id = o.cart_id
JOIN dbo.Buyer b ON b.buyer_id = c.buyer_id
GROUP BY b.country
ORDER BY revenue DESC;


--satıcı başına ürün sayısı--
SELECT p.seller_id, COUNT(*) AS product_cnt
FROM Products p
GROUP BY p.seller_id
ORDER BY product_cnt DESC;

--kategori başına ürün sayısı--
SELECT p.category_name, COUNT(*) AS product_cnt
FROM Products p
GROUP BY p.category_name
ORDER BY product_cnt DESC;


--Aylara göre indirim performansı ve net satış
SELECT
  YEAR(o.order_date)  AS [year],
  MONTH(o.order_date) AS [month],
  COUNT(*) AS line_count,
  SUM(CASE WHEN oi.discount_id IS NULL THEN 0 ELSE 1 END) AS discounted_lines,
  SUM(oi.quantity * oi.unit_discount) AS total_discount_amount,
  SUM(oi.sub_total) AS net_sales
FROM Orders o
JOIN Order_Item oi ON oi.order_id = o.order_id
GROUP BY YEAR(o.order_date), MONTH(o.order_date)
ORDER BY [year], [month];

--Mevsime göre ortalama teslimat süresi
SELECT
  YEAR(s.delivered_date) AS [year],
  CASE
    WHEN MONTH(s.delivered_date) IN (12,1,2) THEN 'Winter'
    WHEN MONTH(s.delivered_date) IN (3,4,5)  THEN 'Spring'
    WHEN MONTH(s.delivered_date) IN (6,7,8)  THEN 'Summer'
    ELSE 'Autumn'
  END AS season,
  AVG(CAST(DATEDIFF(day, o.order_date, s.delivered_date) AS decimal(10,2))) AS avg_delivery_days
FROM Shipment s
JOIN Orders o ON o.order_id = s.order_id
WHERE s.delivered_date IS NOT NULL
GROUP BY
  YEAR(s.delivered_date),
  CASE
    WHEN MONTH(s.delivered_date) IN (12,1,2) THEN 'Winter'
    WHEN MONTH(s.delivered_date) IN (3,4,5)  THEN 'Spring'
    WHEN MONTH(s.delivered_date) IN (6,7,8)  THEN 'Summer'
    ELSE 'Autumn'
  END
ORDER BY [year], season;

--30yaş
SELECT
  b.buyer_id,
  b.first_name,
  b.last_name,
  b.birthdate,
  DATEDIFF(year, b.birthdate, CAST(GETDATE() AS date))
    - CASE
        WHEN DATEADD(year, DATEDIFF(year, b.birthdate, CAST(GETDATE() AS date)), b.birthdate) > CAST(GETDATE() AS date)
        THEN 1 ELSE 0
      END AS age
FROM Buyer b
WHERE
  DATEDIFF(year, b.birthdate, CAST(GETDATE() AS date))
    - CASE
        WHEN DATEADD(year, DATEDIFF(year, b.birthdate, CAST(GETDATE() AS date)), b.birthdate) > CAST(GETDATE() AS date)
        THEN 1 ELSE 0
      END > 30
ORDER BY age DESC;

--yaş grubuna göre buyer sayısı
WITH buyer_age AS (
  SELECT
    b.buyer_id,
    DATEDIFF(year, b.birthdate, CAST(GETDATE() AS date))
      - CASE
          WHEN DATEADD(year, DATEDIFF(year, b.birthdate, CAST(GETDATE() AS date)), b.birthdate) > CAST(GETDATE() AS date)
          THEN 1 ELSE 0
        END AS age
  FROM Buyer b
)
SELECT
  CASE
    WHEN age < 18 THEN '0-17'
    WHEN age BETWEEN 18 AND 24 THEN '18-24'
    WHEN age BETWEEN 25 AND 34 THEN '25-34'
    WHEN age BETWEEN 35 AND 44 THEN '35-44'
    WHEN age BETWEEN 45 AND 54 THEN '45-54'
    ELSE '55+'
  END AS age_group,
  COUNT(*) AS buyer_count
FROM buyer_age
GROUP BY
  CASE
    WHEN age < 18 THEN '0-17'
    WHEN age BETWEEN 18 AND 24 THEN '18-24'
    WHEN age BETWEEN 25 AND 34 THEN '25-34'
    WHEN age BETWEEN 35 AND 44 THEN '35-44'
    WHEN age BETWEEN 45 AND 54 THEN '45-54'
    ELSE '55+'
  END
ORDER BY age_group;
--en çok sipariş olan ay
SELECT TOP 1
  YEAR(o.order_date)  AS [year],
  MONTH(o.order_date) AS [month],
  COUNT(*) AS order_count
FROM Orders o
GROUP BY YEAR(o.order_date), MONTH(o.order_date)
ORDER BY order_count DESC;
--sipariş ne kadar satıldı ve kalan stok
SELECT
  p.product_id,
  p.product_name,
  p.stock_quantity AS current_stock,
  ISNULL(SUM(oi.quantity), 0) AS total_sold,
  (p.stock_quantity - ISNULL(SUM(oi.quantity), 0)) AS stock_minus_sales
FROM Products p
LEFT JOIN Order_Item oi ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.stock_quantity
ORDER BY stock_minus_sales ASC;



--mesleğe göre sipariş sayısı veciro
SELECT
  b.job_title,
  COUNT(*)           AS order_count,
  SUM(o.total_price) AS revenue
FROM Orders o
JOIN Cart  c ON c.cart_id = o.cart_id
JOIN Buyer b ON b.buyer_id = c.buyer_id
GROUP BY b.job_title
ORDER BY revenue DESC, order_count DESC, b.job_title;


--siparişe dönüşen sepetler--
SELECT c.cart_id, c.buyer_id, c.created_at
FROM Cart c  INNER JOIN Orders o ON c.cart_id = o.cart_id;

--siparişe dönüşmeyen sepetler--
SELECT c.cart_id, c.buyer_id, c.created_at
FROM Cart c
LEFT JOIN Orders o ON o.cart_id = c.cart_id
WHERE o.cart_id IS NULL;

--İndirim uygulanmış ürün satırı sayısı
SELECT
  COUNT(*) AS OrderItemCnt,
  SUM(CASE WHEN unit_discount > 0 THEN 1 ELSE 0 END) AS DiscountedLines
FROM Order_Item;

--sepetteki farklı ürün sayısı--
SELECT c.cart_id, c.buyer_id, COUNT(*) AS line_cnt, SUM(ci.quantity) AS total_qty
FROM Cart c
JOIN Cart_Item ci on ci.cart_id = c.cart_id
GROUP BY c.cart_id, c.buyer_id
ORDER by total_qty DESC;


-- başarılı / başarısız ödeme sayısı
SELECT payment_status, COUNT(*) AS cnt
FROM payment
GROUP BY payment_status;

--her cart için yapılan deneme sayısı
SELECT cart_id, COUNT(*) AS attempt_rows, MAX(attempt_number) AS attempt_cnt
FROM Payment
GROUP BY cart_id
ORDER BY attempt_cnt DESC;

--İndirim uygulanmış order item’lar
SELECT *
FROM Order_Item
WHERE unit_discount > 0
ORDER BY unit_discount DESC;

--orderitemdan sipariş toplamı
SELECT oi.order_id,
       SUM(oi.quantity) AS total_qty,
       CAST(SUM(oi.sub_total) AS DECIMAL(10,2)) AS calc_total_price
FROM Order_Item oi
GROUP BY oi.order_id
ORDER BY oi.order_id;

--orders.total_pricela hesaplanan tutar ile orderitemdan toplanan sipariş tutarı aynı mı
SELECT o.order_id,
       o.total_qty, x.calc_qty,
       o.total_price, x.calc_price
FROM Orders o
JOIN (
    SELECT order_id,
           SUM(quantity) AS calc_qty,
           CAST(SUM(sub_total) AS DECIMAL(10,2)) AS calc_price
    FROM Order_Item
    GROUP BY order_id
) x ON x.order_id = o.order_id
order by o.order_id;

--Stoğu azalan ürünler
SELECT  product_id, product_name, stock_quantity
FROM Products
ORDER BY stock_quantity ASC;

--satılmış ürünler
SELECT DISTINCT oi.product_id, p.product_name
FROM Order_Item oi
JOIN Products p ON p.product_id = oi.product_id;

--Hiç satılmayan ürünler
SELECT p.product_id, p.product_name
FROM Products p
LEFT JOIN Order_Item oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

SELECT COUNT(*) AS ReviewCnt FROM Review;
SELECT * FROM Review ORDER BY review_date DESC;

SELECT COUNT(*) AS WishlistCnt FROM dbo.Wishlist;
SELECT TOP 10 * FROM dbo.Wishlist ORDER BY added_at DESC;

--en çok yorum alan ürünler
SELECT TOP 10
  p.product_id, p.product_name,
  COUNT(*) AS review_cnt,
  AVG(CAST(r.rating AS float)) AS avg_rating
FROM Products p
JOIN Review r ON r.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY review_cnt DESC;

--En yüksek puanlı ürünler
SELECT TOP 10
  p.product_id, p.product_name,
  AVG(CAST(r.rating AS float)) AS avg_rating,
  COUNT(*) AS review_cnt
FROM Products p
JOIN Review r ON r.product_id = p.product_id
GROUP BY p.product_id, p.product_name
HAVING COUNT(*) >= 3
ORDER BY avg_rating DESC, review_cnt DESC;

--Hiç yorum almamış ürünler
SELECT p.product_id, p.product_name
FROM Products p
LEFT JOIN Review r ON r.product_id = p.product_id
WHERE r.product_id IS NULL
ORDER BY p.product_id;

--buyer kaç yorum yapmış
SELECT b.buyer_id, b.first_name, b.last_name,
       COUNT(*) AS review_cnt
FROM Buyer b
JOIN Review r ON r.buyer_id = b.buyer_id
GROUP BY b.buyer_id, b.first_name, b.last_name
ORDER BY review_cnt DESC;

--aktif wishlist
SELECT w.buyer_id, w.product_id, p.product_name, w.added_at
FROM Wishlist w
JOIN Products p ON p.product_id = w.product_id
WHERE w.removed_at IS NULL
ORDER BY w.added_at DESC;

--Wishlist’e eklenip sonra kaldırılan ürünler
SELECT w.buyer_id, w.product_id, p.product_name, w.added_at, w.removed_at
FROM Wishlist w
JOIN Products p ON p.product_id = w.product_id
WHERE w.removed_at IS NOT NULL
ORDER BY w.removed_at DESC;

--En çok wishlist’e giren ürünler
SELECT TOP 10
  p.product_id, p.product_name,
  COUNT(*) AS wish_cnt
FROM Wishlist w
JOIN Products p ON p.product_id = w.product_id
GROUP BY p.product_id, p.product_name
ORDER BY wish_cnt DESC;

--Siparişlerde toplam “indirim miktarı”
SELECT
  SUM(quantity * unit_discount) AS total_discount_amount
FROM Order_Item;

--Seller bazında ciro
SELECT TOP 10
  s.seller_id, s.store_name,
  SUM(oi.sub_total) AS revenue
FROM Seller s
JOIN Products p ON p.seller_id = s.seller_id
JOIN Order_Item oi ON oi.product_id = p.product_id
GROUP BY s.seller_id, s.store_name
ORDER BY revenue DESC;


--Ortalama kargo ücreti
SELECT AVG(shipping_cost) AS avg_shipping_cost
FROM dbo.Shipment;

--En pahalı kargo
SELECT TOP 1 *
FROM Shipment
ORDER BY shipping_cost DESC;

--Sipariş + kargo durumu
SELECT o.order_id, o.order_date,
       s.status, s.shipping_cost,
       s.in_transit_date, s.delivered_date
FROM dbo.Orders o
JOIN dbo.Shipment s ON s.order_id = o.order_id
ORDER BY o.order_date DESC;


--teslim süresi
SELECT o.order_id,
       DATEDIFF(day, o.order_date, s.delivered_date) AS delivery_days
FROM dbo.Orders o
JOIN dbo.Shipment s ON s.order_id = o.order_id
WHERE s.delivered_date IS NOT NULL
ORDER BY delivery_days DESC;


SELECT  p.product_name
FROM dbo.Products p
LEFT JOIN dbo.Review r
    ON r.product_id = p.product_id
WHERE r.product_id IS NULL;

SELECT w.buyer_id, w.product_id
FROM dbo.Wishlist w
LEFT JOIN dbo.Order_Item oi
    ON oi.product_id = w.product_id
WHERE oi.product_id IS NULL;

SELECT c.cart_id, c.buyer_id
FROM dbo.Cart c
LEFT JOIN dbo.Orders o
    ON o.cart_id = c.cart_id
WHERE o.cart_id IS NULL;

SELECT w.buyer_id, COUNT(*) AS wishlist_item_cnt
FROM dbo.Wishlist w
LEFT JOIN dbo.Cart c
    ON c.buyer_id = w.buyer_id
LEFT JOIN dbo.Orders o
    ON o.cart_id = c.cart_id
LEFT JOIN dbo.Order_Item oi
    ON oi.order_id = o.order_id
   AND oi.product_id = w.product_id
WHERE oi.product_id IS NULL
GROUP BY w.buyer_id;


--EN AZ 10 ÜRÜNÜ OLAN SELLER
SELECT
  p.seller_id,
  COUNT(*) AS product_cnt
FROM dbo.Products p
GROUP BY p.seller_id
HAVING COUNT(*) >= 10
ORDER BY product_cnt DESC;



SELECT
  p.product_id, p.product_name,
  COUNT(*) AS review_cnt,
  CAST(AVG(CAST(r.rating AS float)) AS DECIMAL(3,2)) AS avg_rating
FROM dbo.Products p
JOIN dbo.Review r ON r.product_id = p.product_id
GROUP BY p.product_id, p.product_name
HAVING COUNT(*) >= 2
   AND AVG(CAST(r.rating AS float)) >= 4.0
ORDER BY avg_rating DESC, review_cnt DESC;

--review’u olan ürünlere sahip bir SELLER
SELECT TOP 1 s.seller_id
FROM dbo.Seller s
JOIN dbo.Products p ON p.seller_id = s.seller_id
JOIN dbo.Review r ON r.product_id = p.product_id
ORDER BY s.seller_id;


SELECT TOP 10 p.cart_id, MAX(p.attempt_number) AS last_attempt
FROM dbo.Payment p
GROUP BY p.cart_id
ORDER BY last_attempt DESC;







