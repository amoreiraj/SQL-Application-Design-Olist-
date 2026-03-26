# SQL Application Design - Olist Brazilian E-Commerce

A relational database design and analysis project built on the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle.

The goal was to move beyond writing isolated queries and learn to think like a database designer, importing raw CSV files, normalising them into a relational schema in MySQL, generating an ER diagram, and writing business queries grounded in real table relationships.

**Skills demonstrated:** SQL · Database design · ERD · Data cleaning · Exploratory data analysis · Business analysis

<p align="center">
  <b>Tech & tools used</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/SQL-336791?logo=postgresql&logoColor=white" alt="SQL"/>
  <img src="https://img.shields.io/badge/Power%20BI-F2C811?logo=powerbi&logoColor=black" alt="Power BI"/>
  <img src="https://img.shields.io/badge/Excel-217346?logo=microsoft-excel&logoColor=white" alt="Excel"/> 
</p>

---

## Table of Contents

- [Project Overview](#project-overview)
- [Dataset](#dataset)
- [Data Analysis Workflow](#data-analysis-workflow)
  - [1. Business Understanding](#1-business-understanding)
  - [2. Data Collection](#2-data-collection)
  - [3. Data Exploration — EDA](#3-data-exploration--eda)
  - [4. Data Cleaning and Preparation](#4-data-cleaning-and-preparation)
    - [Phase 0 — Master Audit](#phase-0--master-audit)
    - [Phase 0.1 — Referential Integrity](#phase-01--referential-integrity-checks)
    - [Phase 0.2 — Range and Format Validation](#phase-02--range-and-format-validation)
    - [Phase 1 — Type Standardisation](#phase-1--type-standardisation)
    - [Phase 1.1 — Convert Blanks to NULL](#phase-11--convert-blanks-to-null)
    - [Phase 1.2 — Trim Whitespace](#phase-12--trim-whitespace)
    - [Phase 1.3 — Create Cleaned Views](#phase-13--create-cleaned-views)
    - [Phase 1.4 — Feature Engineering](#phase-14--feature-engineering)
    - [Phase 0.3 — Post-Cleaning Audit](#phase-03--post-cleaning-audit)
  - [5. Data Modelling and Analysis](#5-data-modelling-and-analysis)
  - [6. Evaluation and Interpretation](#6-evaluation-and-interpretation)
  - [7. Reporting and Visualisation](#7-reporting-and-visualisation)
- [ER Diagram](#er-diagram)
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

This project follows a structured data analysis workflow:


### 1. Business Understanding

**Problem identified:** The Olist system assigns a new `customer_id` to the same person every time they place an order. This means a single real customer appears as multiple distinct customers in the database.

**Impact:** Any analysis using `customer_id` to count customers will overcount real customers and cannot measure repeat purchase behaviour.

**Decision:** All customer-level analysis in this project uses `customer_unique_id`. The `customer_id` column is used only to join the `orders` and `customers` tables.

---

### 2. Data Collection

The dataset was downloaded from Kaggle and imported into MySQL Workbench as 9 separate tables. No transformations were applied at import, the goal was to preserve the raw data exactly as provided before beginning any cleaning or analysis.

---

### 3. Data Exploration - EDA

This phase focused on understanding how customers are represented and validating whether key counts were accurate.

<img width="999" height="692" alt="image" src="https://github.com/user-attachments/assets/cd34dd30-5baf-452e-a990-3b540db02846" />

This query overcounts real customers because the same person can have multiple customer_id values (one per order).

```sql
SELECT COUNT(DISTINCT customer_id)
FROM orders; -- Total: 99441
```

<img width="210" height="97" alt="image" src="https://github.com/user-attachments/assets/3422a9e7-8961-4e94-aac6-57634cd22a95" />

The following query is used to identify customer_unique_id and the number of orders ordered as qtd_ids. 

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
4. **Data Cleaning and Preparation**

Cleaning is divided into two phases. **Phase 0** audits the data before any changes are made. **Phase 1** applies the actual fixes. A final re-audit in Phase 0.3 confirms the cleaning worked as intended.

---

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

5. **Data Modelling / Analysis**
6. **Evaluation / Interpretation**
7. **Reporting / Visualisation / Communication**
