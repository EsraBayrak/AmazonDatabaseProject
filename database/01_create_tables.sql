USE [Amazon];
GO




CREATE TABLE Account (
    email VARCHAR(100) NOT NULL,
    user_type VARCHAR(10) NOT NULL
        CONSTRAINT CK_Account_UserType CHECK (user_type IN ('BUYER','SELLER')),

    CONSTRAINT PK_Account PRIMARY KEY (email)
);





CREATE TABLE Buyer (
    buyer_id INT IDENTITY(1,1) PRIMARY KEY,

    email VARCHAR(100) UNIQUE NOT NULL,

    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,


    country VARCHAR(50) NOT NULL,
    city VARCHAR(100) NOT NULL,

    gender CHAR(1) NOT NULL CHECK (gender IN ('M','F')),
    birthdate DATE NOT NULL,

    job_title VARCHAR(50) NOT NULL,

    CONSTRAINT FK_Buyer_Account
        FOREIGN KEY (email) REFERENCES Account(email)
);




CREATE TABLE Seller (
    seller_id INT IDENTITY(1,1) PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,

    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL,

    country VARCHAR(50) NOT NULL,
    city    VARCHAR(100) NOT NULL,

    gender CHAR(1) NOT NULL CHECK (gender IN ('M','F')),
    birthdate DATE NOT NULL,

    seller_type VARCHAR(20) NOT NULL,
    store_name  VARCHAR(100) NOT NULL,

    store_rating DECIMAL(3,2) NOT NULL
        CHECK (store_rating >= 0 AND store_rating <= 5),

    join_date DATE NOT NULL DEFAULT CAST(GETDATE() AS date),

    job_title VARCHAR(50) NOT NULL,

    CONSTRAINT FK_Seller_Account
        FOREIGN KEY (email) REFERENCES Account(email)
);



CREATE TABLE Category (
  category_name VARCHAR(100) NOT NULL PRIMARY KEY
);

CREATE TABLE Products (
  product_id INT IDENTITY(1,1) PRIMARY KEY,
  product_name VARCHAR(100) NOT NULL,
  category_name VARCHAR(100) NOT NULL,
  seller_id INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
  stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
  brand_name VARCHAR(50) NOT NULL,
  rating DECIMAL(3,2) NOT NULL DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
  review_count INT NOT NULL DEFAULT 0 CHECK (review_count >= 0),
  uploaded_at DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),

  CONSTRAINT FK_Products_CategoryName FOREIGN KEY (category_name)
    REFERENCES Category(category_name),

  CONSTRAINT FK_Products_Seller FOREIGN KEY (seller_id)
    REFERENCES Seller(seller_id)
);


CREATE TABLE Discount (
    discount_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,

    discount_name VARCHAR(100) NOT NULL,
    discount_type VARCHAR(20) NOT NULL
        CONSTRAINT CK_Discount_Type CHECK (discount_type IN ('percentage', 'amount')),
    discount_value DECIMAL(10,2) NOT NULL
        CONSTRAINT CK_Discount_Value CHECK (discount_value >= 0),

    start_date DATE NOT NULL,
    end_date   DATE NOT NULL,
    CONSTRAINT CK_Discount_DateRange CHECK (end_date >= start_date),

    CONSTRAINT FK_Discount_Product
        FOREIGN KEY (product_id) REFERENCES Products(product_id)
);




CREATE TABLE Cart (
    cart_id INT IDENTITY(1,1) PRIMARY KEY,

    buyer_id INT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Cart_Buyer
        FOREIGN KEY (buyer_id) REFERENCES Buyer(buyer_id)
);

CREATE TABLE Cart_Item (
    cart_id INT NOT NULL,
    product_id INT NOT NULL,

    quantity INT NOT NULL CHECK (quantity > 0),

    CONSTRAINT PK_Cart_Item PRIMARY KEY (cart_id, product_id),

    CONSTRAINT FK_CartItem_Cart
        FOREIGN KEY (cart_id) REFERENCES Cart(cart_id),

    CONSTRAINT FK_CartItem_Product
        FOREIGN KEY (product_id) REFERENCES Products(product_id)
);



CREATE TABLE Payment (
    cart_id INT NOT NULL,

    attempt_number INT NOT NULL
        CONSTRAINT CK_Payment_AttemptNumber CHECK (attempt_number > 0),

    payment_type VARCHAR(30) NOT NULL
        CONSTRAINT CK_Payment_Type
        CHECK (payment_type IN ('Credit Card','Debit Card')),

    payment_status VARCHAR(20) NOT NULL
        CONSTRAINT CK_Payment_Status
        CHECK (payment_status IN ('Success','Failed')),

    CONSTRAINT PK_Payment
        PRIMARY KEY (cart_id, attempt_number),

    CONSTRAINT FK_Payment_Cart
        FOREIGN KEY (cart_id) REFERENCES Cart(cart_id)
);






CREATE TABLE Orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,

    cart_id INT NOT NULL,
    total_qty   INT NOT NULL DEFAULT 0 CHECK (total_qty >= 0),
    total_price DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (total_price >= 0),

    order_date DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT UQ_Orders_Cart UNIQUE (cart_id),

    CONSTRAINT FK_Orders_Cart
        FOREIGN KEY (cart_id) REFERENCES Cart(cart_id)
);



CREATE TABLE Order_Item (
    order_id   INT NOT NULL,
    product_id INT NOT NULL,

    quantity INT NOT NULL CHECK (quantity > 0),

    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),

    unit_discount DECIMAL(10,2) NOT NULL DEFAULT 0
        CHECK (unit_discount >= 0),   

    final_unit_price AS (unit_price - unit_discount),
    sub_total AS (quantity * (unit_price - unit_discount)),

    discount_id INT NULL,

    CONSTRAINT FK_OrderItem_Order
        FOREIGN KEY (order_id) REFERENCES Orders(order_id),

    CONSTRAINT FK_OrderItem_Products
        FOREIGN KEY (product_id) REFERENCES Products(product_id),

    CONSTRAINT FK_OrderItem_Discount
        FOREIGN KEY (discount_id) REFERENCES Discount(discount_id),

    CONSTRAINT PK_Order_Item
        PRIMARY KEY (order_id, product_id),

    CONSTRAINT CK_OrderItem_DiscountNotMoreThanPrice
        CHECK (unit_discount <= unit_price)
);

  


CREATE TABLE Shipment (
    order_id INT NOT NULL,

    tracking_number VARCHAR(100) NULL,

    shipping_cost DECIMAL(10,2) NOT NULL
        CONSTRAINT CK_Shipment_ShippingCost CHECK (shipping_cost >= 0),

    in_transit_date DATETIME NULL,
    delivered_date  DATETIME NULL,

    status VARCHAR(30) NOT NULL
        CONSTRAINT CK_Shipment_Status CHECK (status IN ('Preparing','In Transit','Delivered','Cancelled')),

    CONSTRAINT PK_Shipment
        PRIMARY KEY (order_id),

    CONSTRAINT FK_Shipment_Order
        FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);


CREATE TABLE Review (
    buyer_id   INT NOT NULL,
    product_id INT NOT NULL,

    review_date DATETIME NOT NULL DEFAULT GETDATE(),

    rating INT NOT NULL
        CHECK (rating BETWEEN 1 AND 5),

    CONSTRAINT PK_Review
        PRIMARY KEY (buyer_id, product_id),

    CONSTRAINT FK_Review_Buyer
        FOREIGN KEY (buyer_id) REFERENCES Buyer(buyer_id),

    CONSTRAINT FK_Review_Product
        FOREIGN KEY (product_id) REFERENCES Products(product_id)
);



CREATE TABLE Wishlist (
    buyer_id   INT NOT NULL,
    product_id INT NOT NULL,

    added_at DATETIME NOT NULL DEFAULT GETDATE(),
    removed_at DATETIME NULL,


    CONSTRAINT PK_Wishlist
        PRIMARY KEY (buyer_id, product_id),

    CONSTRAINT FK_Wishlist_Buyer
        FOREIGN KEY (buyer_id) REFERENCES Buyer(buyer_id),

    CONSTRAINT FK_Wishlist_Product
        FOREIGN KEY (product_id) REFERENCES Products(product_id)
);


GO
