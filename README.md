# SQL Application Design - Olist Brazilian E-Commerce

A relational database design and analysis project built on the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle.

The goal was to move beyond writing isolated queries and learn to think like a database designer, importing raw CSV files, normalising them into a relational schema in MySQL, generating an ER diagram, and writing business queries grounded in real table relationships.

                                                   **Skills and tools used:**

<p align="center">
  <img src="https://img.shields.io/badge/MySQL-4479A1?logo=mysql&logoColor=white" alt="MySQL"/>
  <img src="https://img.shields.io/badge/Database%20Design-4B8BBE?logo=databricks&logoColor=white" alt="Database Design"/>
  <img src="https://img.shields.io/badge/ERD-FF6F61?logo=diagrams.net&logoColor=white" alt="ERD"/>
  <img src="https://img.shields.io/badge/Data%20Cleaning-6A5ACD?logo=python&logoColor=white" alt="Data Cleaning"/>
  <img src="https://img.shields.io/badge/EDA-20B2AA?logo=jupyter&logoColor=white" alt="EDA"/>
  <img src="https://img.shields.io/badge/Business%20Analysis-FFB347?logo=googleanalytics&logoColor=white" alt="Business Analysis"/>
  <img src="https://img.shields.io/badge/Power%20BI-F2C811?logo=powerbi&logoColor=black" alt="Power BI"/>
  <img src="https://img.shields.io/badge/Excel-217346?logo=microsoft-excel&logoColor=white" alt="Excel"/> 
</p>

---
 
## Table of Contents

- [Project Overview](#project-overview)
- [Dataset](#dataset)
- [The Data Analysis Process](#the-data-analysis-process)
  - [1. Business Understanding](#1-business-understanding)
  - [2. Data Gathering](#2-data-gathering)
  - [3. Data Understanding , EDA](#3-data-understanding)
  - [4. Data Cleaning and Preparation](#4-data-cleaning-and-preparation)
    - [Phase 0 , Master Audit](#phase-0--master-audit)
    - [Phase 0.1 , Referential Integrity](#phase-01--referential-integrity-checks)
    - [Phase 0.2 , Range and Format Validation](#phase-02--range-and-format-validation)
    - [Phase 1 , Type Standardisation](#phase-1--type-standardisation)
    - [Phase 1.1 , Convert Blanks to NULL](#phase-11--convert-blanks-to-null)
    - [Phase 1.2 , Trim Whitespace](#phase-12--trim-whitespace)
    - [Phase 1.3 , Create Cleaned Views](#phase-13--create-cleaned-views)
    - [Phase 1.4 , Feature Engineering](#phase-14--feature-engineering)
    - [Phase 0.3 , Post-Cleaning Audit](#phase-03--post-cleaning-audit)
  - [5. Data Modelling and Analysis](#5-data-modelling-and-analysis)
  - [6. Evaluation and Interpretation](#6-evaluation-and-interpretation)
  - [7. Reporting and Visualisation](#7-reporting-and-visualisation)
- [8. ER Diagram](#er-diagram)
- [Temporal Coverage](#temporal-coverage)

---

## Project Overview

| Item | Detail |
|------|--------|
| **Dataset** | Olist Brazilian E-Commerce (Kaggle) |
| **Database** | MySQL via MySQL Workbench |
| **Tables** | 9 (normalised from raw CSV files) |
| **Rows** | ~500k across all tables |
| **Period covered** | 1 January 2017 – 31 August 2018 |
| **Focus** | Database design · data cleaning · business analysis |

---

## Dataset

The dataset contains 9 CSV files representing a normalised e-commerce schema. Each file maps directly to a table in MySQL.

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
| olist_sellers_dataset.csv                 | sellers                        | seller_id, zip_code_prefix, city, state                                               | ~3k          

> **Note on geolocation:** This table is a lookup reference, not a relational table. One zip code prefix maps to multiple lat/lng coordinates, so it has no formal foreign key relationship. It is joined via `zip_code_prefix` using averaged coordinates after normalisation in Phase 1.3.


--- 

## The Data Analysis Process:

<img width="946" height="617" alt="image" src="https://github.com/user-attachments/assets/463750ed-51db-45f3-8976-329aa5f11d43" />


### 1. Business Understanding

**Problem identified:** The Olist system assigns a new `customer_id` to the same person every time they place an order. This means a single real customer appears as multiple distinct customers in the database.

**Impact:** Any analysis using `customer_id` to count customers will overcount real customers and cannot measure repeat purchase behaviour.

**Decision:** All customer-level analysis in this project uses `customer_unique_id`. The `customer_id` column is used only to join the `orders` and `customers` tables.

---

### 2. Data Gathering

The dataset was downloaded from Kaggle and imported into MySQL Workbench as 9 separate tables. No transformations were applied at import, the goal was to preserve the raw data exactly as provided before beginning any cleaning or analysis.

---

### 3. Data Exploration - EDA

This phase focused on understanding how customers are represented and validating whether key counts were accurate.

<img width="999" height="692" alt="image" src="https://github.com/user-attachments/assets/cd34dd30-5baf-452e-a990-3b540db02846" />

#### Confirming the customer ID problem

This query overcounts real customers because the same person can have multiple customer_id values (one per order). The following query returns 99,441 unique customers, but this count is misleading:

```sql
SELECT COUNT(DISTINCT customer_id)
FROM orders; -- Total: 99441
```

<img width="210" height="97" alt="image" src="https://github.com/user-attachments/assets/3422a9e7-8961-4e94-aac6-57634cd22a95" />

The following query is used to identify customer_unique_id and the number of orders ordered as qtd_ids. The same person receives a different `customer_id` for each order they place. The query below confirms this , it finds customers with more than one `customer_id`, proving that `customer_id` is order-scoped, not person-scoped:


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


**Finding:** Multiple customers have 2 or more `customer_id` values, meaning they placed more than one order. This confirms that `customer_unique_id` must be used for accurate customer counts and repeat purchase analysis.

---

### 4. Data Cleaning and Preparation

Cleaning is divided into two phases. **Phase 0** audits the data before any changes are made. **Phase 1** applies the actual fixes. A final re-audit in Phase 0.3 confirms the cleaning worked as intended.

---

- Phase 0 , Master audit , Perform all checks before making any changes to the database.
- Phase 0.1 , Referential integrity checks , find all orphan rows
- Phase 0.2 , Range and format validation , ghost orders, review scores, negative prices
- Phase 1 , ALTER TABLE , standardise types across all 9 tables
- Phase 1.1 , Convert blanks to NULL , all tables, all text columns
- Phase 1.2 , TRIM whitespace , IDs and category strings
- Phase 1.3 , Create views , v_products_translated, v_reviews_deduped, olist_geo_clean
- Phase 1.4 , Feature engineering , delivery_delta_days and delivery_status
- Phase 0.3 again , Re-run master audit , confirm numbers changed as expected

--- 

**Phase 0: Initial Data Audit (Prior Checks)**

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

**Finding:** A small number of delivered orders have no recorded delivery date. These are flagged as data quality issues and excluded from delivery performance analysis.

---
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

**Finding:** Vouchers are the primary source of zero-value payments. Three rows have `not_defined` as the payment type. Both are documented and excluded from revenue calculations.

---

**3. NULL check across key order columns**

```sql
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)                        AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)                     AS null_customer_id,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END)                    AS null_status,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END)        AS null_purchase_ts,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END)   AS null_delivery_date
FROM orders;
```

![Output: NULL check on orders](https://github.com/user-attachments/assets/0d6bbf77-a529-4a7f-b3d9-f9795e7b7300)

**Finding:** Primary key and status columns are clean. The high count in `null_delivery_date` is expected , non-delivered orders have no delivery date by design.

---

**4. Products with no category**

```sql
SELECT COUNT(*) AS no_category
FROM products
WHERE product_category_name IS NULL;
```

![Output: products with no category](https://github.com/user-attachments/assets/164c77ca-4706-4d83-b1ab-14b8b4949600)

**Finding:** 610 products have no category name. These are mapped to `'others'` via the translated products view created in Phase 1.3.

---

**5. Review score range validation**

```sql
SELECT DISTINCT review_score
FROM order_reviews
ORDER BY review_score;
```

![Output: review score range](https://github.com/user-attachments/assets/72802fb2-4b30-4f2d-9cf9-ddd9a54b5223)

**Finding:** All review scores fall within the valid range of 1 to 5. No out-of-range values detected.

---

**6. Negative price check**

```sql
SELECT COUNT(*) AS negative_prices
FROM order_items
WHERE price < 0;
```
<img width="196" height="90" alt="image" src="https://github.com/user-attachments/assets/9764217c-8f65-4c83-bb26-ed865e410aa6" />

**Finding:** Zero negative prices. All price values are valid.

---
#### Phase 0.1 - Referential Integrity Checks

These queries identify orphan rows, records that reference a parent row that does not exist. Orphan rows cause silent JOIN failures.

```sql
-- Orders with no matching customer
SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Order items with no matching order
SELECT COUNT(*) AS orphan_items
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Order items with no matching product
SELECT COUNT(*) AS orphan_products
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Order items with no matching seller
SELECT COUNT(*) AS orphan_sellers
FROM order_items oi
LEFT JOIN sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- Payments with no matching order
SELECT COUNT(*) AS orphan_payments
FROM order_payments op
LEFT JOIN orders o ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Reviews with no matching order
SELECT COUNT(*) AS orphan_reviews
FROM order_reviews r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;
```

---
#### Phase 0.2 - Range and Format Validation

This audit checks for hidden empty strings, cells that appear blank but are stored as `''` rather than `NULL`. Standard `IS NULL` checks miss these entirely.

```sql
-- Customers table
SELECT
    SUM(CASE WHEN TRIM(customer_city)  = '' THEN 1 ELSE 0 END) AS city_empty,
    SUM(CASE WHEN customer_city IS NULL     THEN 1 ELSE 0 END) AS city_null,
    SUM(CASE WHEN TRIM(customer_state) = '' THEN 1 ELSE 0 END) AS state_empty,
    SUM(CASE WHEN customer_state IS NULL    THEN 1 ELSE 0 END) AS state_null
FROM customers;

-- Products table
SELECT
    SUM(CASE WHEN TRIM(product_category_name) = '' THEN 1 ELSE 0 END) AS category_empty,
    SUM(CASE WHEN product_category_name IS NULL    THEN 1 ELSE 0 END) AS category_null
FROM products;

-- Reviews table
SELECT
    SUM(CASE WHEN TRIM(review_comment_title)   = '' THEN 1 ELSE 0 END) AS title_empty,
    SUM(CASE WHEN TRIM(review_comment_message) = '' THEN 1 ELSE 0 END) AS message_empty,
    SUM(CASE WHEN review_score IS NULL              THEN 1 ELSE 0 END) AS score_null
FROM order_reviews;

-- Sellers table
SELECT
    SUM(CASE WHEN TRIM(seller_city)  = '' THEN 1 ELSE 0 END) AS city_empty,
    SUM(CASE WHEN seller_city IS NULL    THEN 1 ELSE 0 END) AS city_null,
    SUM(CASE WHEN TRIM(seller_state) = '' THEN 1 ELSE 0 END) AS state_empty,
    SUM(CASE WHEN seller_state IS NULL   THEN 1 ELSE 0 END) AS state_null
FROM sellers;
```

---

#### Phase 1 - Type Standardisation

All ID columns are confirmed as `CHAR(32)`, the correct type for 32-character UUID hashes. No `ALTER TABLE` was required. This was validated using `DESCRIBE` on each table and confirmed by the absence of join failures during EDA.

> **Decision:** Skipping `ALTER TABLE` on ID columns. All keys are already `CHAR(32)`, which is appropriate for UUIDs of this format. Changing to `VARCHAR(50)` would require dropping and recreating all foreign key constraints with no practical benefit for this dataset.

---

#### Phase 1.1 - Convert Blanks to NULL

CSV imports often store empty cells as `''` rather than `NULL`. This causes aggregate functions like `AVG()` and `COUNT()` to behave incorrectly, and breaks `COALESCE` smart defaults. All identified empty strings are converted to `NULL`.

```sql
-- Orders
UPDATE orders
SET order_status = NULL
WHERE TRIM(order_status) = '';

-- Products
UPDATE products
SET product_category_name = NULL
WHERE TRIM(product_category_name) = '';

-- Customers
UPDATE customers SET customer_city  = NULL WHERE TRIM(customer_city)  = '';
UPDATE customers SET customer_state = NULL WHERE TRIM(customer_state) = '';

-- Sellers
UPDATE sellers SET seller_city  = NULL WHERE TRIM(seller_city)  = '';
UPDATE sellers SET seller_state = NULL WHERE TRIM(seller_state) = '';

-- Reviews
UPDATE order_reviews SET review_comment_title   = NULL WHERE TRIM(review_comment_title)   = '';
UPDATE order_reviews SET review_comment_message = NULL WHERE TRIM(review_comment_message) = '';
```

---

#### Phase 1.2 - Trim Whitespace

Leading or trailing spaces in ID and category columns cause silent join failures, two values that look identical in a query result may not match because one has a hidden space.

```sql
-- Trim product IDs and category names
UPDATE products
SET product_id            = TRIM(product_id),
    product_category_name = TRIM(product_category_name);

-- Trim and standardise state codes to uppercase
UPDATE customers SET customer_state = TRIM(UPPER(customer_state));
UPDATE sellers   SET seller_state   = TRIM(UPPER(seller_state));
```

---

#### Phase 1.3 - Create Cleaned Views

Rather than modifying the raw tables, cleaned and enriched versions are exposed as views. This preserves the original data while providing clean, analysis-ready references.

```sql
-- View 1: Products with English category names
-- 610 NULL categories are mapped to 'others'
CREATE VIEW v_products_translated AS
SELECT
    p.product_id,
    COALESCE(t.product_category_name_english, 'others') AS category_en
FROM products p
LEFT JOIN product_category_translation t
    ON p.product_category_name = t.product_category_name;

-- View 2: Deduplicated reviews
-- Keeps only the most recent review per order
-- Prevents double-counting of sentiment in aggregate queries
CREATE VIEW v_reviews_deduped AS
SELECT r.*
FROM order_reviews r
INNER JOIN (
    SELECT order_id, MAX(review_creation_date) AS latest
    FROM order_reviews
    GROUP BY order_id
) latest_r
    ON  r.order_id            = latest_r.order_id
    AND r.review_creation_date = latest_r.latest;

-- Table 3: Normalised geolocation (1 row per zip code prefix)
-- The raw geolocation table has ~1M rows with multiple coordinates per prefix.
-- Averaging lat/lng creates a single representative point per prefix,
-- preventing a row explosion when joining to customers or sellers.
CREATE TABLE geo_clean AS
SELECT
    geolocation_zip_code_prefix,
    AVG(geolocation_lat)           AS avg_lat,
    AVG(geolocation_lng)           AS avg_lng,
    TRIM(UPPER(geolocation_city))  AS city,
    TRIM(UPPER(geolocation_state)) AS state
FROM geolocation
GROUP BY geolocation_zip_code_prefix;
```

---

#### Phase 1.4 - Feature Engineering

New calculated columns are created to support delivery performance analysis. These are exposed as a view rather than modifying the base table.

```sql
-- Delivery performance view
-- delivery_delta_days: positive = late, negative = early, 0 = exactly on time
CREATE VIEW v_delivery_performance AS
SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    DATEDIFF(
        order_delivered_customer_date,
        order_estimated_delivery_date
    ) AS delivery_delta_days,
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'On time'
        WHEN DATEDIFF(
                order_delivered_customer_date,
                order_estimated_delivery_date
             ) <= 3
            THEN 'Slightly late'
        ELSE 'Significantly late'
    END AS delivery_status
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
```

---

#### Phase 0.3 - Post-Cleaning Audit

Re-run the master audit after all Phase 1 steps to confirm the cleaning worked as expected. Numbers should reflect what was changed.

```sql
SELECT
    'orders' AS tbl,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_pk,
    SUM(CASE WHEN order_status IS NULL
              OR TRIM(order_status) = '' THEN 1 ELSE 0 END) AS bad_status,
    SUM(CASE WHEN order_delivered_customer_date IS NULL
             AND order_status = 'delivered' THEN 1 ELSE 0 END) AS ghost_deliveries
FROM orders
UNION ALL
SELECT
    'products',
    COUNT(*),
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN TRIM(product_category_name) = '' THEN 1 ELSE 0 END)
FROM products
UNION ALL
SELECT
    'order_reviews',
    COUNT(*),
    SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN TRIM(review_comment_message) = '' THEN 1 ELSE 0 END)
FROM order_reviews;
```

---

### 5. Data Modelling and Analysis

_In progress_

---

### 6. Evaluation and Interpretation

_In progress_

---

### 7. Reporting and Visualisation

_In progress_

---

## ER Diagram

![Olist Entity Relationship Diagram](https://github.com/user-attachments/assets/OLIST_ERD_22032026.png)

The diagram shows the nine tables and their relationships. Key observations:

- `orders` is the central fact table, it connects directly to `customers`, `order_items`, `order_payments`, and `order_reviews`
- `order_items` connects to `products` and `sellers`
- `products` connects to `product_category_translation` for English category names
- `geolocation` has no formal foreign key, it is a lookup table joined via `zip_code_prefix`

---
<img width="675" height="896" alt="image" src="https://github.com/user-attachments/assets/9caec884-16db-470f-b820-6055c5eae088" />

