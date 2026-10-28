-- here we start to check for each column for duplicates and nulls and missing values and misspelling words
-- and standarized columns to be in a good view
-- Table Columns 
--Transaction_ID * , Order_ID * ,Customer_ID * , Customer_Name *,Customer_Age *,Customer_Gender*
-- Customer_Segment* ,Order_Date* ,Order_Time*,Sales_Channel* ,Store_ID ,Store_Name
-- Country ,Region ,City Product_ID Product_Name Product_Category Product_Subcategory
-- Quantity Unit_Price Discount_Percentage Sales_Amount Cost_Amount Profit Payment_Method
-- Order_Status Shipping_Method Delivery_Days Return_Flag Return_Reason Sales_Representative
-- Promotion_Code Customer_Rating Inventory_Level Order_Year

SELECT * FROM bronze.salesinfo; 
--  start with keys and ids
SELECT COUNT(transaction_id)  --count rows  
FROM bronze.salesinfo;

SELECT COUNT(DISTINCT transaction_id)  --count DISTINCT rows
FROM bronze.salesinfo;

SELECT  COUNT(transaction_id) - COUNT(DISTINCT transaction_id)  --COUNT DUPLICATED ROWS 45 duplicate row
FROM bronze.salesinfo
-- check for duplicated row and count duplicates
SELECT transaction_id , COUNT(transaction_id)
FROM bronze.salesinfo
GROUP BY transaction_id
ORDER BY COUNT(transaction_id) DESC 
LIMIT 45;

SELECT DISTINCT transaction_id 
FROM bronze.salesinfo         -- choose non dublicate values 18000

----------------------------------------------------------------------------------------------------
-- check customer name - age - gender - segment
-- start with customer names 
SELECT COUNT(*) FILTER (WHERE customer_name IS NULL) AS Null_values, -- 108 null value
       COUNT(*) FILTER (WHERE customer_name <> TRIM(customer_name)) AS has_spaces,
       COUNT(DISTINCT customer_id) AS distinct_customers
FROM bronze.salesinfo;
SELECT CASE WHEN customer_name IS NULL THEN 'N/A' -- CONVERT NULL VALUES TO N/A AND TRIM AND CAPITAL FIRST LETTER FOR EACH NAME
			ELSE INITCAP(TRIM(customer_name))
		END AS custoemr_name
FROM bronze.salesinfo
-------------------------------------------------------------------------------------------------------
-- check for customer age
SELECT COUNT(*) FILTER (WHERE customer_age IS NULL) AS Null_values,  -- 218 null value
       MIN(customer_age) AS min_age,
	   MAX(customer_age) AS max_age
FROM bronze.salesinfo;
SELECT customer_id,
		MODE() WITHIN GROUP (ORDER BY customer_age) AS customer_age_mode
FROM bronze.salesinfo
GROUP BY customer_id
------------------------------------------------------------------------------------------------
--check for customer gender
SELECT COUNT(*) FILTER (WHERE customer_gender IS NULL) AS Null_values,  --162 null value
       COUNT(*) FILTER (WHERE customer_gender <> TRIM(customer_gender)) AS has_spaces
FROM bronze.salesinfo;

SELECT DISTINCT customer_gender
FROM bronze.salesinfo

-- standarize values of gender for male and female and N/A for null
SELECT CASE WHEN customer_gender IN ('male' ,'Male') THEN 'male'
			WHEN customer_gender IN('Female' , 'FEMALE') THEN 'female'
			ELSE 'N/A'
		END AS customer_gender 
FROM bronze.salesinfo
------------------------------------------------------------------------------------
SELECT COUNT(*) FILTER (WHERE customer_segment IS NULL) AS Null_values,  --look like  a clean text 
       COUNT(*) FILTER (WHERE customer_segment <> TRIM(customer_segment)) AS has_spaces
FROM bronze.salesinfo;

SELECT DISTINCT customer_segment
FROM bronze.salesinfo
-- write it in a good text way
SELECT INITCAP(TRIM(customer_segment)) AS customer_segment
FROM bronze.salesinfo
-------------------------------------------------------------------------------------
--check order date 
SELECT  COUNT(*) FILTER (WHERE order_date IS NULL) AS missing_values,  -- now change it clean
		COUNT(*) FILTER (WHERE order_date > CURRENT_DATE) AS future_orders,
		MIN(order_date) AS first_order,
		MAX(order_date) AS last_order
FROM bronze.salesinfo	
--check order time
SELECT  COUNT(*) FILTER (WHERE order_time IS NULL) AS missing_values,  -- now change it clean
		MIN(order_time) AS first_order,
		MAX(order_time) AS last_order
FROM bronze.salesinfo	
---------------------------------------------------------------------------------
--check sales channel 
SELECT COUNT(*) FILTER (WHERE sales_channel IS NULL) AS Null_values,
       COUNT(*) FILTER (WHERE sales_channel <> TRIM(sales_channel)) AS has_spaces,
       COUNT(DISTINCT sales_channel) AS distinct_customers
FROM bronze.salesinfo;

SELECT DISTINCT sales_channel AS distinct_customers  -- CLEAN TEXT COLUMN
FROM bronze.salesinfo;

---------------------------------------------------------------------------------
-- CHECK STORE ID 
SELECT COUNT(DISTINCT store_id) -- THERE ARE 12 STORES
FROM bronze.salesinfo

SELECT COUNT(store_id)  --NO NULLS
FROM bronze.salesinfo
WHERE store_id IS NULL
---------------------------------------------------------------------------------
-- CHECK STORE NAME 

SELECT COUNT(*) FILTER (WHERE store_name IS NULL) AS Null_values,
       COUNT(*) FILTER (WHERE store_name <> TRIM(store_name)) AS has_spaces,
       COUNT(DISTINCT store_name) AS distinct_stores
FROM bronze.salesinfo;


SELECT DISTINCT store_name AS distinct_stores  -- CLEAN TEXT COLUMN
FROM bronze.salesinfo;

---------------------------------------------------------------------------------
-- check country column
SELECT COUNT(*) FILTER (WHERE country IS NULL) AS Null_values,  -- clean
       COUNT(*) FILTER (WHERE country <> TRIM(country)) AS has_spaces,
       COUNT(DISTINCT country) AS distinct_countries
FROM bronze.salesinfo;

SELECT DISTINCT country AS distinct_countries  -- CLEAN TEXT COLUMN
FROM bronze.salesinfo;
---------------------------------------------------------------------------------
-- check region
SELECT COUNT(*) FILTER (WHERE region IS NULL) AS Null_values,  -- clean
       COUNT(*) FILTER (WHERE region <> TRIM(region)) AS has_spaces,
       COUNT(DISTINCT region) AS distinct_regions
FROM bronze.salesinfo;

SELECT DISTINCT region AS distinct_regions  -- CLEAN TEXT COLUMN
FROM bronze.salesinfo;
---------------------------------------------------------------------------------
-- check city
SELECT COUNT(*) FILTER (WHERE city IS NULL) AS Null_values,  -- should clean cloumn from multi values 
       COUNT(*) FILTER (WHERE city <> TRIM(city)) AS has_spaces,
       COUNT(DISTINCT city) AS distinct_city
FROM bronze.salesinfo;

SELECT DISTINCT city AS distinct_city  --same values with diff text
FROM bronze.salesinfo;

SELECT INITCAP(TRIM(city))
FROM bronze.salesinfo

SELECT CASE WHEN city IN('LOS ANGELES','Los Angeles') THEN 'Los Angeles'
			WHEN city IN('munich','Munich') THEN 'Munich'
			WHEN city IN(' New York ','New York') THEN 'New York'
			ELSE city
		END AS city
FROM bronze.salesinfo
---------------------------------------------------------------------------------
--check product id
SELECT COUNT(DISTINCT product_id) -- THERE ARE 28 product
FROM bronze.salesinfo

SELECT COUNT(product_id)  --NO NULLS
FROM bronze.salesinfo
WHERE product_id IS NULL
---------------------------------------------------------------------------------
--check product name 
SELECT COUNT(*) FILTER (WHERE product_name IS NULL) AS Null_values,  -- should clean null values fill with product id
       COUNT(*) FILTER (WHERE product_name <> TRIM(product_name)) AS has_spaces,
       COUNT(DISTINCT product_name) AS distinct_products
FROM bronze.salesinfo;

SELECT DISTINCT product_name AS distinct_products  --same values with diff text
FROM bronze.salesinfo;

SELECT product_id ,product_name
FROM bronze.salesinfo
GROUP BY product_id , product_name
ORDER BY product_id

WITH product_lookup AS (     --make a standard table for product id with product name 
    SELECT product_id,
           MODE() WITHIN GROUP (ORDER BY TRIM(product_name)) AS product_name
    FROM bronze.salesinfo
    WHERE product_name IS NOT NULL AND TRIM(product_name) <> ''
    GROUP BY product_id
)
SELECT r.transaction_id,
       r.product_id,
       r.product_name                                   AS name_raw,
       COALESCE(NULLIF(TRIM(r.product_name), ''), l.product_name, 'Unknown Product') AS product_name
FROM bronze.salesinfo r
LEFT JOIN product_lookup l USING (product_id);

---------------------------------------------------------------------------------
-- check product category 
SELECT COUNT(*) FILTER (WHERE product_category IS NULL) AS Null_values,  -- clean
       COUNT(*) FILTER (WHERE product_category <> TRIM(product_category)) AS has_spaces,
       COUNT(DISTINCT product_category) AS distinct_products
FROM bronze.salesinfo;

SELECT DISTINCT product_category AS distinct_products  --clean text need to trim and initcap 
FROM bronze.salesinfo;
---------------------------------------------------------------------------------
-- check subcategory
SELECT COUNT(*) FILTER (WHERE product_subcategory IS NULL) AS Null_values,  -- clean 
       COUNT(*) FILTER (WHERE product_subcategory <> TRIM(product_subcategory)) AS has_spaces,
       COUNT(DISTINCT product_subcategory) AS distinct_products
FROM bronze.salesinfo;

SELECT DISTINCT product_subcategory AS distinct_products  --clean text need to trim and initcap 
FROM bronze.salesinfo;
---------------------------------------------------------------------------------
--check for quantity column
SELECT COUNT(*) FILTER (WHERE quantity IS NULL)   AS qty_missing,
       MIN(quantity)                              AS min_qty,
       MAX(quantity)                              AS max_qty,
       ROUND(AVG(quantity), 2)                    AS avg_qty,
       COUNT(*) FILTER (WHERE quantity = 0)       AS qty_zero,
       COUNT(*) FILTER (WHERE quantity < 0)       AS qty_negative
FROM bronze.salesinfo;
-- HANDLE negative values and zero  values
SELECT sales_amount , unit_price , quantity ,
		ROUND(sales_amount / unit_price , 0) AS new_quantity
FROM bronze.salesinfo
WHERE quantity < 0 OR quantity =0

---------------------------------------------------------------------------------
-- check unit price            
SELECT COUNT(*) FILTER (WHERE unit_price IS NULL)   AS qty_missing,
       MIN(unit_price)                              AS min_qty,
       MAX(unit_price)                              AS max_qty,
       ROUND(AVG(unit_price), 2)                    AS avg_qty,
       COUNT(*) FILTER (WHERE unit_price = 0)       AS qty_zero,
       COUNT(*) FILTER (WHERE unit_price < 0)       AS qty_negative
FROM bronze.salesinfo;   -- clean 
---------------------------------------------------------------------------------
--check discaountpercentage
SELECT COUNT(*) FILTER (WHERE discount_percentage IS NULL)   AS qty_missing,
       MIN(discount_percentage)                              AS min_qty,
       MAX(discount_percentage)                              AS max_qty,
       ROUND(AVG(discount_percentage), 2)                    AS avg_qty,
       COUNT(*) FILTER (WHERE discount_percentage = 0)       AS qty_zero,
       COUNT(*) FILTER (WHERE discount_percentage < 0)       AS qty_negative,
	   COUNT(*) FILTER (WHERE discount_percentage > 0)
FROM bronze.salesinfo;   -- clean column
SELECT DISTINCT discount_percentage
FROM bronze.salesinfo
---------------------------------------------------------------------------------
--check for sales amount
SELECT COUNT(*) FILTER (WHERE sales_amount IS NULL)   AS qty_missing,
       MIN(sales_amount)                              AS min_qty,
       MAX(sales_amount)                              AS max_qty,
       ROUND(AVG(sales_amount), 2)                    AS avg_qty,
       COUNT(*) FILTER (WHERE sales_amount = 0)       AS qty_zero,
       COUNT(*) FILTER (WHERE sales_amount < 0)       AS qty_negative,
	   COUNT(*) FILTER (WHERE sales_amount > 0)
FROM bronze.salesinfo;  --clean
---------------------------------------------------------------------------------
--check for cost amount
SELECT COUNT(*) FILTER (WHERE cost_amount IS NULL)   AS qty_missing,
       MIN(cost_amount)                              AS min_qty,
       MAX(cost_amount)                              AS max_qty,
       ROUND(AVG(cost_amount), 2)                    AS avg_qty,
       COUNT(*) FILTER (WHERE cost_amount = 0)       AS qty_zero,
       COUNT(*) FILTER (WHERE cost_amount < 0)       AS qty_negative,
	   COUNT(*) FILTER (WHERE cost_amount > 0)
FROM bronze.salesinfo;  --clean
---------------------------------------------------------------------------------
--check profit
SELECT COUNT(*) FILTER (WHERE profit IS NULL)   AS qty_missing,
       MIN(profit)                              AS min_qty,
       MAX(profit)                              AS max_qty,
       ROUND(AVG(profit), 2)                    AS avg_qty,
       COUNT(*) FILTER (WHERE profit = 0)       AS qty_zero,
       COUNT(*) FILTER (WHERE profit < 0)       AS qty_negative,
	   COUNT(*) FILTER (WHERE profit > 0)
FROM bronze.salesinfo; --need to recalculate profit and sales amount and cost amount

---------------------------------------------------------------------------------
--check payment method
SELECT COUNT(*) FILTER (WHERE payment_method IS NULL) AS Null_values,  -- clean 
       COUNT(*) FILTER (WHERE payment_method <> TRIM(payment_method)) AS has_spaces,
       COUNT(DISTINCT payment_method) AS distinct_products
FROM bronze.salesinfo;

SELECT DISTINCT payment_method AS distinct_products  --clean text need to trim and initcap 
FROM bronze.salesinfo;

WITH ap AS (
SELECT CASE WHEN payment_method IS NULL THEN 'Unknown'
			WHEN payment_method = 'DebitCard' THEN 'Debit Card'
			ELSE INITCAP(TRIM( payment_method))
		END AS payment_method
FROM bronze.salesinfo)
SELECT DISTINCT payment_method
FROM ap
---------------------------------------------------------------------------------
--check order status
SELECT COUNT(*) FILTER (WHERE order_status IS NULL) AS Null_values,  -- clean 
       COUNT(*) FILTER (WHERE order_status <> TRIM(order_status)) AS has_spaces,
       COUNT(DISTINCT order_status) AS distinct_products
FROM bronze.salesinfo;

SELECT DISTINCT order_status AS distinct_products  --clean text need to trim and initcap 
FROM bronze.salesinfo;
--celan column values 
WITH status AS (
	SELECT INITCAP(TRIM(order_status)) AS order_status
	FROM bronze.salesinfo
)
SELECT DISTINCT order_status
FROM status

---------------------------------------------------------------------------------
-- check shipping method
SELECT COUNT(*) FILTER (WHERE shipping_method IS NULL) AS Null_values,  -- clean 
       COUNT(*) FILTER (WHERE shipping_method <> TRIM(shipping_method)) AS has_spaces,
       COUNT(DISTINCT shipping_method) AS distinct_products
FROM bronze.salesinfo;

SELECT DISTINCT shipping_method AS distinct_products  --clean 
FROM bronze.salesinfo;
---------------------------------------------------------------------------------
--check order days
SELECT COUNT(*) FILTER (WHERE delivery_days IS NULL)   AS qty_missing,
       MIN(delivery_days)                              AS min_qty,
       MAX(delivery_days)                              AS max_qty,
       ROUND(AVG(delivery_days), 2)                    AS avg_qty,
       COUNT(*) FILTER (WHERE delivery_days = 0)       AS qty_zero,
       COUNT(*) FILTER (WHERE delivery_days < 0)       AS qty_negative,
	   COUNT(*) FILTER (WHERE delivery_days > 0)
FROM bronze.salesinfo; --if make analysis it need to be cleaned
---------------------------------------------------------------------------------
SELECT COUNT(*) FILTER (WHERE return_flag IS NULL) AS Null_values,  -- clean 
       COUNT(*) FILTER (WHERE return_flag <> TRIM(return_flag)) AS has_spaces,
       COUNT(DISTINCT return_flag) AS distinct_products
FROM bronze.salesinfo;

SELECT DISTINCT return_flag AS distinct_products  --clean 
FROM bronze.salesinfo;
---------------------------------------------------------------------------------
SELECT COUNT(*) FILTER (WHERE return_reason IS NULL) AS Null_values,  -- there are null values need cleaning
       COUNT(*) FILTER (WHERE return_reason <> TRIM(return_reason)) AS has_spaces,
       COUNT(DISTINCT return_reason) AS distinct_products
FROM bronze.salesinfo;

SELECT DISTINCT return_reason AS distinct_products  
FROM bronze.salesinfo;
---------------------------------------------------------------------------------
SELECT COUNT(*) FILTER (WHERE sales_representative IS NULL) AS Null_values,  -- clean
       COUNT(*) FILTER (WHERE sales_representative <> TRIM(sales_representative)) AS has_spaces,
       COUNT(DISTINCT sales_representative) AS distinct_products
FROM bronze.salesinfo;

SELECT DISTINCT sales_representative AS distinct_products  
FROM bronze.salesinfo;
---------------------------------------------------------------------------------
SELECT COUNT(*) FILTER (WHERE promotion_code IS NULL) AS Null_values,  -- i don't use
       COUNT(*) FILTER (WHERE promotion_code <> TRIM(promotion_code)) AS has_spaces,
       COUNT(DISTINCT promotion_code) AS distinct_products
FROM bronze.salesinfo;
SELECT CASE WHEN promotion_code IS NULL THEN 'No Promotion'
			 ELSE INITCAP(TRIM(promotion_code))
		 END AS promotion_code
FROM bronze.salesinfo
SELECT DISTINCT promotion_code AS distinct_products  
FROM bronze.salesinfo;
----------------------------------------------------------------------------------------
SELECT COUNT(*) FILTER (WHERE customer_rating IS NULL)   AS qty_missing, -- 
       MIN(customer_rating)                              AS min_qty,
       MAX(customer_rating)                              AS max_qty,
       ROUND(AVG(customer_rating), 2)                    AS avg_qty,
       COUNT(*) FILTER (WHERE customer_rating = 0)       AS qty_zero,
       COUNT(*) FILTER (WHERE customer_rating < 0)       AS qty_negative,
	   COUNT(*) FILTER (WHERE customer_rating > 0)
FROM bronze.salesinfo;


SELECT COUNT(*) FILTER (WHERE inventory_level IS NULL)   AS qty_missing, -- 
       MIN(inventory_level)                              AS min_qty,
       MAX(inventory_level)                              AS max_qty,
       ROUND(AVG(inventory_level), 2)                    AS avg_qty,
       COUNT(*) FILTER (WHERE inventory_level = 0)       AS qty_zero,
       COUNT(*) FILTER (WHERE inventory_level < 0)       AS qty_negative,
	   COUNT(*) FILTER (WHERE inventory_level > 0)
FROM bronze.salesinfo;

SELECT COUNT(*) FILTER (WHERE order_year IS NULL)   AS qty_missing, -- 
       MIN(order_year)                              AS min_qty,
       MAX(order_year)                              AS max_qty,
       ROUND(AVG(order_year), 2)                    AS avg_qty,
       COUNT(*) FILTER (WHERE order_year = 0)       AS qty_zero,
       COUNT(*) FILTER (WHERE order_year < 0)       AS qty_negative,
	   COUNT(*) FILTER (WHERE order_year > 0)
FROM bronze.salesinfo;

SELECT DISTINCT order_year
FROM bronze.salesinfo

-----------------------------------------------------------------------------------------------------------------------------------------
-- Silver Check verification after loading data
SELECT
    COUNT(*) AS rows_total,            
    COUNT(*) - COUNT(DISTINCT transaction_id) AS duplicate_ids,          
    COUNT(*) FILTER (WHERE product_name IS NULL) AS product_name_null,      
    COUNT(*) FILTER (WHERE customer_age NOT BETWEEN 10 AND 100) AS bad_age_left,          
    COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM order_date) <> order_year) AS year_mismatch,        
    COUNT(*) FILTER (WHERE ABS((sales_amount - cost_amount) - profit) > 0.02) AS profit_mismatch,  
    COUNT(*) FILTER (WHERE customer_gender <> TRIM(customer_gender)
                        OR city <> TRIM(city)
                        OR product_category <> TRIM(product_category)
                        OR payment_method <> TRIM(payment_method)) AS has_spaces,           
    COUNT(DISTINCT customer_gender) AS gender_values,         
    COUNT(DISTINCT payment_method) AS payment_values,         
    COUNT(DISTINCT product_category) AS category_values,     
    COUNT(DISTINCT city) AS city_values,         
    COUNT(DISTINCT order_status) AS status_values           
FROM silver.salesinfo;

--Conclusion table for each gender, payment , category , status,channel  avilable values 
SELECT 'gender' AS col, customer_gender AS value, COUNT(*) FROM silver.salesinfo GROUP BY 2
UNION ALL SELECT 'payment',  payment_method,   COUNT(*) FROM silver.salesinfo GROUP BY 2
UNION ALL SELECT 'category', product_category, COUNT(*) FROM silver.salesinfo GROUP BY 2
UNION ALL SELECT 'status',   order_status,     COUNT(*) FROM silver.salesinfo GROUP BY 2
UNION ALL SELECT 'channel',  sales_channel,    COUNT(*) FROM silver.salesinfo GROUP BY 2
ORDER BY col, value;
--this is the end 






