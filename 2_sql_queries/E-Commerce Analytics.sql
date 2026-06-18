-- Project: UK E-Commerce Transactions Analytics
-- Dataset: UCI Online Retail II (1,067,371 raw rows)
-- Tool: PostgreSQL 18
-- Create table retail_transcations 
CREATE TABLE retail_transactions (
    invoice         VARCHAR(20),
    stockcode       VARCHAR(20),
    description     VARCHAR(255),
    quantity        INTEGER,
    invoicedate     TIMESTAMP,
    price           NUMERIC(10,2),
    customer_id     VARCHAR(20),
    country         VARCHAR(100)
);
-- Load the CSV dataset file
COPY retail_transactions(
    invoice, stockcode, description, quantity,
    invoicedate, price, customer_id, country
)
FROM 'C:/Users/DELL/Downloads/online_retail_II.csv'
DELIMITER ','
CSV HEADER
ENCODING 'LATIN1';
SELECT COUNT(*) FROM retail_transactions;

-- Step-1:  Data Quality Check & Data Cleaning -
   -- Check raw data quality
   
SELECT
    COUNT(*)                                            AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL)        AS null_customers,
    COUNT(*) FILTER (WHERE quantity <= 0)              AS negative_quantity,
    COUNT(*) FILTER (WHERE price <= 0)                 AS zero_price,
    COUNT(*) FILTER (WHERE invoice LIKE 'C%')          AS cancelled_orders,
    COUNT(DISTINCT customer_id)                        AS unique_customers,
    COUNT(DISTINCT invoice)                            AS unique_invoices,
    COUNT(DISTINCT country)                            AS unique_countries
FROM retail_transactions;

   -- Create cleaned view (we use a view so original data stays untouched)

CREATE VIEW clean_transactions AS
SELECT
    invoice,
    stockcode,
    description,
    quantity,
    invoicedate,
    price,
    customer_id,
    country,
    ROUND((quantity * price)::NUMERIC, 2) AS total_price
FROM retail_transactions
WHERE customer_id IS NOT NULL
  AND quantity > 0
  AND price > 0
  AND invoice NOT LIKE 'C%';
  SELECT COUNT(*) FROM clean_transactions;
  
-- Step 2: Monthly Revenue Trend -

  SELECT
    TO_CHAR(DATE_TRUNC('month', invoicedate), 'YYYY-MM') AS year_month,
    ROUND(SUM(total_price)::NUMERIC, 2)                  AS monthly_revenue,
    COUNT(DISTINCT invoice)                              AS total_orders,
    COUNT(DISTINCT customer_id)                          AS unique_customers
FROM clean_transactions
GROUP BY DATE_TRUNC('month', invoicedate)
ORDER BY DATE_TRUNC('month', invoicedate);

-- Step-3: Top 10 Products by Revenue -

SELECT
    description                                AS product_name,
    ROUND(SUM(total_price)::NUMERIC, 2)        AS total_revenue,
    SUM(quantity)                              AS total_units_sold,
    COUNT(DISTINCT invoice)                    AS total_orders,
    COUNT(DISTINCT customer_id)                AS unique_customers,
    ROUND(AVG(price)::NUMERIC, 2)              AS avg_unit_price
FROM clean_transactions
WHERE description IS NOT NULL
  AND description NOT IN ('Manual', 'POSTAGE', 'DOTCOM POSTAGE', 'CRUK Commission')
GROUP BY description
ORDER BY total_revenue DESC
LIMIT 10;

-- Step-4: Top 10 International Markets by Revenue -

SELECT
    country,
    ROUND(SUM(total_price)::NUMERIC, 2)        AS total_revenue,
    COUNT(DISTINCT customer_id)                AS unique_customers,
    COUNT(DISTINCT invoice)                    AS total_orders,
    ROUND(AVG(total_price)::NUMERIC, 2)        AS avg_order_value
FROM clean_transactions
WHERE country != 'United Kingdom'
GROUP BY country
ORDER BY total_revenue DESC
LIMIT 10;

-- Step-5: Customer Cohort Retention Analysis -
   -- Find each customer's first purchase month
   
CREATE VIEW customer_cohorts AS
WITH first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoicedate)) AS cohort_month
    FROM clean_transactions
    GROUP BY customer_id
)
SELECT
    ct.customer_id,
    fp.cohort_month,
    DATE_TRUNC('month', ct.invoicedate)    AS invoice_month,
    (EXTRACT('year' FROM AGE(
        DATE_TRUNC('month', ct.invoicedate),
        fp.cohort_month
    )) * 12 +
    EXTRACT('month' FROM AGE(
        DATE_TRUNC('month', ct.invoicedate),
        fp.cohort_month
    )))::INT                               AS cohort_index
FROM clean_transactions ct
JOIN first_purchase fp
  ON ct.customer_id = fp.customer_id;
  
   -- Count unique customers per cohort per month index
   
SELECT
    TO_CHAR(cohort_month, 'YYYY-MM')           AS cohort_month,
    cohort_index,
    COUNT(DISTINCT customer_id)                AS customers
FROM customer_cohorts
GROUP BY cohort_month, cohort_index
ORDER BY cohort_month, cohort_index
LIMIT 50;

-- Step-6: RFM Customer Segmentation -

WITH rfm_base AS (
    SELECT
        customer_id,
        MAX(invoicedate)                           AS last_purchase_date,
        COUNT(DISTINCT invoice)                    AS frequency,
        ROUND(SUM(total_price)::NUMERIC, 2)        AS monetary,
        (SELECT MAX(invoicedate) FROM clean_transactions) AS snapshot_date
    FROM clean_transactions
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        EXTRACT('day' FROM (snapshot_date - last_purchase_date))::INT  AS recency_days,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY last_purchase_date DESC)  AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC)            AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC)             AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score)                  AS rfm_score,
    CASE
        WHEN (r_score + f_score + m_score) >= 10 THEN 'Champions'
        WHEN (r_score + f_score + m_score) >= 8
             AND r_score >= 3               THEN 'Loyal Customers'
        WHEN (r_score + f_score + m_score) >= 8
             AND r_score < 3                THEN 'Cant Lose Them'
        WHEN (r_score + f_score + m_score) >= 6
             AND r_score >= 3               THEN 'Potential Loyalists'
        WHEN (r_score + f_score + m_score) >= 6
             AND r_score < 3                THEN 'At Risk'
        WHEN (r_score + f_score + m_score) >= 4 THEN 'Need Attention'
        ELSE 'Lost'
    END                                            AS segment
FROM rfm_scores
ORDER BY rfm_score DESC
LIMIT 20;

-- Step-7: Churn Analysis -

WITH rfm_base AS (
    SELECT
        customer_id,
        EXTRACT('day' FROM (
            (SELECT MAX(invoicedate) FROM clean_transactions) - MAX(invoicedate)
        ))::INT                                    AS recency_days,
        COUNT(DISTINCT invoice)                    AS frequency,
        ROUND(SUM(total_price)::NUMERIC, 2)        AS monetary
    FROM clean_transactions
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN recency_days > 90 THEN 'Churned'
        ELSE 'Active'
    END                                            AS churn_status,
    COUNT(*)                                       AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    ROUND(AVG(recency_days)::NUMERIC, 1)           AS avg_recency_days,
    ROUND(AVG(frequency)::NUMERIC, 2)              AS avg_frequency,
    ROUND(AVG(monetary)::NUMERIC, 2)               AS avg_monetary
FROM rfm_base
GROUP BY churn_status
ORDER BY churn_status;