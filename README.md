# SQL-Application-Design-Olist

SQL project focused on relational database design using the **Olist Brazilian E-Commerce dataset** (Kaggle): https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

**Main Goal**: Shift from writing isolated queries to designing databases
- import raw CSVs
- normalise data into a relational schema in MySQL
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

2. **Data Gathering / Collection** For this project, the data was downloaded from the public **Olist Brazilian E-Commerce dataset** on Kaggle. The dataset has 9 CSV files containing information about: customers, orders, products, payments, reviews, sellers, and locations.
The files were then imported into MySQL to create the initial tables. At this stage, the goal was simply to load the data exactly as provided, without making changes.

- The Olist dataset has 9 main CSV files that naturally become tables. Key ones:


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

3. **Data Understanding / Exploration (EDA)**

tIME to understand the data. This phase focused on understanding how customers are represented in the data and validating whether customer counts are accurate.

<img width="999" height="692" alt="image" src="https://github.com/user-attachments/assets/cd34dd30-5baf-452e-a990-3b540db02846" />

This query overcounts real customers because the same person can have multiple customer_id values (one per order).

```sql
SELECT COUNT(DISTINCT customer_id)
FROM orders; -- Total: 99441
```

<img width="210" height="97" alt="image" src="https://github.com/user-attachments/assets/3422a9e7-8961-4e94-aac6-57634cd22a95" />

The query below is used to identify customer_unique_id and the number of orders ordered as qtd_ids. 

```sql
SELECT
    customer_unique_id,
    COUNT(DISTINCT customer_id) AS qtd_ids
FROM customers
GROUP BY customer_unique_id
HAVING COUNT(DISTINCT customer_id) > 1;

```
Output (data sample): 
<img width="284" height="224" alt="image" src="https://github.com/user-attachments/assets/534cc02d-2276-4631-9ce2-2cbcf9c27f08" />

** The results confirm that some customers have multiple customer_id values, meaning they placed more than one order. This validates that customer_unique_id must be used for accurate customer-level analysis, while customer_id should only be used to join orders.**

---
4. **Data Cleaning / Preparation**

The data cleaning process has been divided into two phases. Phase 0 (Audiotion) is divided into smaller sessions ranging from Phase 0 to Phase 0.3, and Phase 1 (Cleaning) goes from Phase 1 to Phase 1.4.

- Phase 0 — Master audit — document every number before touching anything
- Phase 0.1 — Referential integrity checks — find all orphan rows
- Phase 0.2 — Range and format validation — ghost orders, review scores, negative prices
- Phase 1 — ALTER TABLE — standardise types across all 9 tables
- Phase 1.1 — Convert blanks to NULL — all tables, all text columns
- Phase 1.2 — TRIM whitespace — IDs and category strings
- Phase 1.3 — Create views — v_products_translated, v_reviews_deduped, olist_geo_clean
- Phase 1.4 — Feature engineering — delivery_delta_days and delivery_status
- Phase 0.3 again — Re-run master audit — confirm numbers changed as expected


**Phase 0: Initial Data Audit (Prior Checks)**

Perform these checks before making any changes to quantify data quality issues.

**1. Identify "Ghost" Orders & Missing Dates**

Why: Finds logical inconsistencies, such as orders marked as 'delivered' that lack a delivery timestamp.

```sql
SELECT COUNT(*) AS delivered_no_date
FROM orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NULL;

 ```
 **Output:**
 
<img width="195" height="98" alt="image" src="https://github.com/user-attachments/assets/1dd7981e-d6d4-432c-97d8-a16a20220a8c" />


**2. Quantify Zero-Value Payments**
   
Why: Identifies "free" orders (vouchers/credits) to avoid skewing Average Order Value (AOV).

```sql
SELECT payment_type,
       COUNT(*) AS total,
       COUNT(CASE WHEN payment_value = 0 THEN 1 END) AS zero_value_count
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY zero_value_count DESC;

```
 **Output:**
 
<img width="293" height="163" alt="image" src="https://github.com/user-attachments/assets/04941641-15ca-4a2a-8ac8-57cb4a08acc5" />


**3. Validate Column Ranges**
Why: Ensures no out-of-range review scores (must be 1–5) or negative financials.

```sql
-- Check review score range
SELECT DISTINCT review_score FROM order_reviews ORDER BY review_score;
```
 **Output:**
 
<img width="191" height="65" alt="image" src="https://github.com/user-attachments/assets/de6d35c4-9620-4622-89bb-48a64bf8bc06" />


```sql
-- Check for negative prices
SELECT COUNT(*) FROM order_items WHERE price < 0;```
```
**Output:**

<img width="107" height="82" alt="image" src="https://github.com/user-attachments/assets/5147ed57-2364-43ef-a161-5e125882ea9a" />

---
** Phase 1: Active Data Cleaning**

**1. Unified Keys & Type Standardisation**
Why: Standardising IDs to VARCHAR(50) ensures JOIN operations are performant and prevents data loss due to collation or type mismatches across the 9 tables.

```sql
ALTER TABLE orders MODIFY order_id VARCHAR(50), MODIFY customer_id VARCHAR(50);
ALTER TABLE order_items MODIFY order_id VARCHAR(50), MODIFY product_id VARCHAR(50), MODIFY seller_id VARCHAR(50);
ALTER TABLE products MODIFY product_id VARCHAR(50);
ALTER TABLE sellers MODIFY seller_id VARCHAR(50);
```
**Output:**


---
```sql
-- 1. Quantify zero-value payments by type
SELECT payment_type,
       COUNT(*) AS total,
       COUNT(CASE WHEN payment_value = 0 THEN 1 END) AS zero_value_count
FROM order_payments
GROUP BY payment_type
ORDER BY zero_value_count DESC;
```

**Output**:

<img width="318" height="154" alt="image" src="https://github.com/user-attachments/assets/24aae013-7fd9-480e-b75a-d3282d3c2605" />

```sql
-- 2. Quantify missing delivery dates
SELECT COUNT(*) AS delivered_no_date
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;
```
**Output**:

<img width="198" height="90" alt="image" src="https://github.com/user-attachments/assets/2ba54c29-5f36-4ffb-8d9e-5527aa8ee0af" />

```sql
-- 3. Check for NULLs across key columns
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)               AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)            AS null_customer_id,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END)           AS null_status,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS null_purchase_ts,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivery_date
FROM orders;
```

**Output**:

<img width="491" height="85" alt="image" src="https://github.com/user-attachments/assets/0d6bbf77-a529-4a7f-b3d9-f9795e7b7300" />

```SQL
-- 4. Check products with no category
SELECT COUNT(*) AS no_category
FROM products
WHERE product_category_name IS NULL;
```

**Output**:

<img width="199" height="78" alt="image" src="https://github.com/user-attachments/assets/164c77ca-4706-4d83-b1ab-14b8b4949600" />

```sql
-- 5. Check review scores for out-of-range values
SELECT DISTINCT review_score
FROM order_reviews
ORDER BY review_score;
```

**Output**:

<img width="200" height="65" alt="image" src="https://github.com/user-attachments/assets/72802fb2-4b30-4f2d-9cf9-ddd9a54b5223" />

---

5. **Data Modeling / Analysis**
6. **Evaluation / Interpretation**
7. **Reporting / Visualization / Communication**
