SET @data_dir = 'C:/path/to/SQL-Application-Design-Olist-/archive/';

-- 1. Customers
SET @sql = CONCAT(
    "LOAD DATA LOCAL INFILE '", @data_dir, "olist_customers_dataset.csv' ",
    "INTO TABLE customers ",
    "FIELDS TERMINATED BY ',' ",
    "ENCLOSED BY '\"' ",
    "LINES TERMINATED BY '\n' ",
    "IGNORE 1 LINES ",
    "(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Geolocation
SET @sql = CONCAT(
    "LOAD DATA LOCAL INFILE '", @data_dir, "olist_geolocation_dataset.csv' ",
    "INTO TABLE geolocation ",
    "FIELDS TERMINATED BY ',' ",
    "ENCLOSED BY '\"' ",
    "LINES TERMINATED BY '\n' ",
    "IGNORE 1 LINES ",
    "(geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. Orders
SET @sql = CONCAT(
    "LOAD DATA LOCAL INFILE '", @data_dir, "olist_orders_dataset.csv' ",
    "INTO TABLE orders ",
    "FIELDS TERMINATED BY ',' ",
    "ENCLOSED BY '\"' ",
    "LINES TERMINATED BY '\n' ",
    "IGNORE 1 LINES ",
    "(order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, ",
    "order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4. Order payments
SET @sql = CONCAT(
    "LOAD DATA LOCAL INFILE '", @data_dir, "olist_order_payments_dataset.csv' ",
    "INTO TABLE order_payments ",
    "FIELDS TERMINATED BY ',' ",
    "ENCLOSED BY '\"' ",
    "LINES TERMINATED BY '\n' ",
    "IGNORE 1 LINES ",
    "(order_id, payment_sequential, payment_type, payment_installments, payment_value)"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 5. Order reviews
SET @sql = CONCAT(
    "LOAD DATA LOCAL INFILE '", @data_dir, "olist_order_reviews_dataset.csv' ",
    "INTO TABLE order_reviews ",
    "FIELDS TERMINATED BY ',' ",
    "ENCLOSED BY '\"' ",
    "LINES TERMINATED BY '\n' ",
    "IGNORE 1 LINES ",
    "(review_id, order_id, review_score, review_comment_title, review_comment_message, ",
    "review_creation_date, review_answer_timestamp)"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 6. Product category translation
SET @sql = CONCAT(
    "LOAD DATA LOCAL INFILE '", @data_dir, "product_category_name_translation.csv' ",
    "INTO TABLE product_category_translation ",
    "FIELDS TERMINATED BY ',' ",
    "ENCLOSED BY '\"' ",
    "LINES TERMINATED BY '\n' ",
    "IGNORE 1 LINES ",
    "(product_category_name, product_category_name_english)"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 7. Products
SET @sql = CONCAT(
    "LOAD DATA LOCAL INFILE '", @data_dir, "olist_products_dataset.csv' ",
    "INTO TABLE products ",
    "FIELDS TERMINATED BY ',' ",
    "ENCLOSED BY '\"' ",
    "LINES TERMINATED BY '\n' ",
    "IGNORE 1 LINES ",
    "(product_id, product_category_name, product_name_length, product_description_length, ",
    "product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 8. Sellers
SET @sql = CONCAT(
    "LOAD DATA LOCAL INFILE '", @data_dir, "olist_sellers_dataset.csv' ",
    "INTO TABLE sellers ",
    "FIELDS TERMINATED BY ',' ",
    "ENCLOSED BY '\"' ",
    "LINES TERMINATED BY '\n' ",
    "IGNORE 1 LINES ",
    "(seller_id, seller_zip_code_prefix, seller_city, seller_state)"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 9. Order items
SET @sql = CONCAT(
    "LOAD DATA LOCAL INFILE '", @data_dir, "olist_order_items_dataset.csv' ",
    "INTO TABLE order_items ",
    "FIELDS TERMINATED BY ',' ",
    "ENCLOSED BY '\"' ",
    "LINES TERMINATED BY '\n' ",
    "IGNORE 1 LINES ",
    "(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Optional quick checks after loading
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'product_category_translation', COUNT(*) FROM product_category_translation
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;
