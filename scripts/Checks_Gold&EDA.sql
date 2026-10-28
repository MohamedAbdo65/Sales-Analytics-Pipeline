--check for calender table
SELECT COUNT(*) AS days, MIN(date_key), MAX(date_key) FROM gold.dim_date;  -- 1461 days if the data spans 2022-2025
SELECT COUNT(*) - COUNT(DISTINCT date_key)    FROM gold.dim_date;
SELECT COUNT(*) AS mis_date
FROM gold.fact_sales f LEFT JOIN gold.dim_date d ON d.date_key = f.order_date
WHERE d.date_key IS NULL; -- expect 0

--check for store table
SELECT * FROM gold.dim_store;
SELECT COUNT(*) - COUNT(DISTINCT store_id)    FROM gold.dim_store;
SELECT COUNT(*) AS null_id
FROM gold.fact_sales f LEFT JOIN gold.dim_store d ON d.store_id = f.store_id
WHERE d.store_id IS NULL;-- expect 0

--check for customer table
SELECT * FROM gold.dim_customer;
SELECT COUNT(*) - COUNT(DISTINCT customer_id) FROM gold.dim_customer;
SELECT COUNT(*) AS null_id
FROM gold.fact_sales f LEFT JOIN gold.dim_customer d ON d.customer_id = f.customer_id
WHERE d.customer_id IS NULL;-- expect 0
--check for product table
SELECT * FROM gold.dim_product;
SELECT COUNT(*) - COUNT(DISTINCT product_id)  FROM gold.dim_product;
SELECT COUNT(*) AS null_id
FROM gold.fact_sales f LEFT JOIN gold.dim_product d ON d.product_id = f.product_id
WHERE d.product_id IS NULL;-- expect 0
--check for fact table
SELECT * FROM gold.fact_sales;

SELECT COUNT(*) - COUNT(DISTINCT transaction_id) FROM gold.fact_sales;

SELECT COUNT(*) AS null_id
FROM gold.fact_sales 
WHERE transaction_id IS NULL;-- expect 0

SELECT COUNT(*) FROM gold.fact_sales
            WHERE transaction_id IS NULL OR order_date IS NULL OR customer_id IS NULL
               OR product_id IS NULL OR store_id IS NULL

SELECT 'category' AS col, product_category AS value, COUNT(*) AS n FROM gold.fact_sales f JOIN gold.dim_product USING (product_id) GROUP BY 2
UNION ALL SELECT 'payment', payment_method, COUNT(*) FROM gold.fact_sales GROUP BY 2
UNION ALL SELECT 'status',  order_status,   COUNT(*) FROM gold.fact_sales GROUP BY 2
UNION ALL SELECT 'channel', sales_channel,  COUNT(*) FROM gold.fact_sales GROUP BY 2
UNION ALL SELECT 'country', country,        COUNT(*) FROM gold.fact_sales f JOIN gold.dim_store USING (store_id) GROUP BY 2
ORDER BY col, value;

SELECT MIN(quantity) AS min_quantity, MAX(quantity) AS max_quantity,
       MIN(unit_price) AS min_price, MAX(unit_price) AS max_price,
       MIN(discount_percentage) AS min_disc, MAX(discount_percentage) AS max_disc,
       MIN(profit) AS min_profit, MAX(profit) AS max_profit,
       MIN(order_date) AS first_day, MAX(order_date) AS last_day
FROM gold.fact_sales;