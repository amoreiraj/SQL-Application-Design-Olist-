-- 1. Customers
CREATE TABLE customers (
    customer_id         CHAR(32) PRIMARY KEY,
    customer_unique_id  CHAR(32) NOT NULL,
    customer_zip_code_prefix INT,
    customer_city       VARCHAR(100),
    customer_state      CHAR(2)
);

-- 2. Orders customers
CREATE TABLE orders (
    order_id                        CHAR(32) PRIMARY KEY,
    customer_id                     CHAR(32) NOT NULL,
    order_status                    VARCHAR(20),
    order_purchase_timestamp        DATETIME,
    order_approved_at               DATETIME,
    order_delivered_carrier_date    DATETIME,
    order_delivered_customer_date   DATETIME,
    order_estimated_delivery_date   DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- 3. Geolocation 
-- DROP TABLE IF EXISTS geolocation;

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10,8),
    geolocation_lng DECIMAL(11,8),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
    -- NO PRIMARY KEY here — allow all duplicates from the CSV
);

-- 4. Order Items
CREATE TABLE order_items (
    order_id            CHAR(32),
    order_item_id       SMALLINT UNSIGNED,   
    product_id          CHAR(32),
    seller_id           CHAR(32),
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id)
    -- FKs added later: product_id, seller_id
);

-- 5. Order Payments
CREATE TABLE order_payments (
    order_id                CHAR(32),
    payment_sequential      TINYINT UNSIGNED,
    payment_type            VARCHAR(30),        -- credit_card, boleto, voucher, debit_card
    payment_installments    TINYINT UNSIGNED,
    payment_value           DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

/*  -- 6. Order Reviews
CREATE TABLE order_reviews (
    review_id                   CHAR(32) PRIMARY KEY,
    order_id                    CHAR(32) NOT NULL,
    review_score                TINYINT UNSIGNED,   -- 1 to 5
    review_comment_title        VARCHAR(500),
    review_comment_message      TEXT,               -- many are long
    review_creation_date        DATETIME,
    review_answer_timestamp     DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
*/ 
-- DROP TABLE IF EXISTS order_reviews;
-- TRUNCATE TABLE order_reviews;

-- 6. Order Reviews NO Primary Key, as review_id and order_id are not unique
-- DROP TABLE IF EXISTS order_reviews;
-- TRUNCATE TABLE order_reviews;
CREATE TABLE order_reviews (
    review_id CHAR(32) NOT NULL,
    order_id CHAR(32) NOT NULL,
    review_score TINYINT UNSIGNED,
    review_comment_title VARCHAR(500),
    review_comment_message TEXT,
    review_creation_date DATE, -- TIMESTAMP 
    review_answer_timestamp TIMESTAMP, -- TIMESTAMP 
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    INDEX idx_order_id (order_id)
);

-- 7. Products
CREATE TABLE products (
    product_id                    CHAR(32) PRIMARY KEY,
    product_category_name         VARCHAR(100),
    product_name_length           SMALLINT,
    product_description_length    SMALLINT,
    product_photos_qty            SMALLINT,
    product_weight_g              INT,
    product_length_cm             SMALLINT,
    product_height_cm             SMALLINT,
    product_width_cm              SMALLINT
);

-- SET FOREIGN_KEY_CHECKS = 0; // I had to set the FK to 0 to be able to insert the products dataset into the dabase
-- TRUNCATE TABLE products; // I then truncated the products table to make sure it was empty
-- SET FOREIGN_KEY_CHECKS = 1; // after loading the dataset I turned the FK back on

-- 8. Sellers
CREATE TABLE sellers (
    seller_id               CHAR(32) PRIMARY KEY,
    seller_zip_code_prefix  INT,
    seller_city             VARCHAR(100),
    seller_state            CHAR(2)
);

-- 9. Product Category Translation
CREATE TABLE product_category_translation (
    product_category_name          VARCHAR(100) PRIMARY KEY,
    product_category_name_english  VARCHAR(100)
);

-- Now add remaining FKs (run after all tables created)
ALTER TABLE order_items
    ADD FOREIGN KEY (product_id) REFERENCES products(product_id),
    ADD FOREIGN KEY (seller_id)  REFERENCES sellers(seller_id);

ALTER TABLE products
    ADD FOREIGN KEY (product_category_name) REFERENCES product_category_translation(product_category_name);
