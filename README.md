# SQL-Application-Design-Olist

SQL project focused on relational database design using the Olist Brazilian E-Commerce dataset (Kaggle) https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

**Goal**: Shift from writing isolated queries to designing databases, import raw CSVs > normalize into relational schema > generate ER diagram > derive business queries from ERD relationships.

**Covers**: ERD creation in MySQL Workbench, multi-table joins, aggregates, subqueries, functions, and real-world e-commerce analysis (revenue, delivery, customer behaviour).

Portfolio showcase for SQL / database design skills.

----

# The Olist dataset:

The Olist dataset has ~9 main CSV files that naturally become tables. Key ones:

- olist_customers_dataset.csv:  customers (customer_id, customer_unique_id, zip_code_prefix, city, state)
- olist_geolocation_dataset.csv: geolocation (zip_code_prefix, lat, lng, city, state)
- olist_orders_dataset.csv : orders (order_id, customer_id, order_status, purchase_timestamp, approved_at, delivered_carrier_date, etc.)
- olist_order_items_dataset.csv : order_items (order_id, item_id, product_id, seller_id, price, freight_value)
- olist_order_payments_dataset.csv : order_payments (order_id, payment_sequential, payment_type, payment_installments, payment_value)
- olist_order_reviews_dataset.csv : order_reviews (review_id, order_id, review_score, review_comment_title, etc.)
- olist_products_dataset.csv : products (product_id, product_category_name, product_name_length, weight, dimensions, etc.)
- product_category_name_translation.csv : category_translation (product_category_name, product_category_name_english)
- olist_sellers_dataset.csv : sellers (seller_id, zip_code_prefix, city, state)

 ---- 
