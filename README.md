# SQL-Application-Design-Olist

SQL project focused on relational database design using the **Olist Brazilian E-Commerce dataset** (Kaggle): https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

** Main Goal**: Shift from writing isolated queries to designing databases
- import raw CSVs
- normalise data into relational schema in MySQL
- generate ER diagram
- write business queries based on the ERD relationships.

**Covers**: 
- ERD creation in MySQL Workbench
-  multi-table joins
-  aggregates
-  subqueries
-  functions
-  real-world e-commerce analysis (revenue, delivery, customer behaviour).

Portfolio showcase for **SQL**, **database design**, and **data analysis** skills.

----

# The Olist dataset:

The Olist dataset has 9 main CSV files that naturally become tables. Key ones:


| File                                      | Table Name                     | Key Columns / Purpose                                                                 | Approx. Rows |
|-------------------------------------------|--------------------------------|---------------------------------------------------------------------------------------|--------------|
| olist_customers_dataset.csv               | customers                      | customer_id, customer_unique_id, zip_code_prefix, city, state                         | ~99k         |
| olist_geolocation_dataset.csv             | geolocation                    | zip_code_prefix, lat, lng, city, state (lookup table – multiple rows per prefix)      | ~1M          |
| olist_orders_dataset.csv                  | orders                         | order_id, customer_id, order_status, purchase/approved/delivered timestamps           | ~99k         |
| olist_order_items_dataset.csv             | order_items                    | order_id, order_item_id, product_id, seller_id, price, freight_value, shipping_limit  | ~113k        |
| olist_order_payments_dataset.csv          | order_payments                 | order_id, payment_sequential, payment_type, installments, payment_value               | ~104k        |
| olist_order_reviews_dataset.csv           | order_reviews                  | review_id, order_id, review_score (1–5), comment_title/message, creation/answer dates | ~99k         |
| olist_products_dataset.csv                | products                       | product_id, category_name, dimensions, weight, photos_qty, description_length         | ~33k         |
| product_category_name_translation.csv     | product_category_translation   | product_category_name (PT), product_category_name_english (EN)                        | 71           |
| olist_sellers_dataset.csv                 | sellers                        | seller_id, zip_code_prefix, city, state                                               | ~3k          |


 ---- 
## Temporal Coverage
- **Start Date**: 01/01/2017
- **End Date**: 06/01/2018

--- 
## the Data Analysis Process:

<img width="946" height="617" alt="image" src="https://github.com/user-attachments/assets/463750ed-51db-45f3-8976-329aa5f11d43" />

This project follows a structured data analysis workflow:

1. **Define the Problem / Business Understanding** The system was designed so that each order is assigned a unique customer_id. As a result, the same person receives a different ID every time they place a new order. This makes each purchase appear to come from a different customer.
The dataset includes a customer_unique_id specifically to identify the real customer across multiple purchases. Without using this field, the business would overcount customers and struggle to measure repeat purchases.
Because the system creates a new customer ID for every order, the business cannot easily track repeat customers or accurately analyse true customer behaviour.

The query below is used to identify customer_unique_id and the number of orders ordered as qtd_ids
```sql
SELECT
    customer_unique_id,
    COUNT(DISTINCT customer_id) AS qtd_ids
FROM customers
GROUP BY customer_unique_id
HAVING COUNT(DISTINCT customer_id) > 1;

```

3. **Data Gathering / Collection** 
4. **Data Understanding / Exploration (EDA)**
5. **Data Cleaning / Preparation**
6. **Data Modeling / Analysis**
7. **Evaluation / Interpretation**
8. **Reporting / Visualization / Communication**
