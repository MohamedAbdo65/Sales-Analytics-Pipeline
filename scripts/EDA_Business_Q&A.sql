--Start to analyze the gold tables and answer business questions 

-- How do revenue and profit change month by month?
CREATE VIEW gold.revenue_profit_MOM AS 
WITH monthly AS (
		SELECT d.year , d.month_name , d.month_number ,
				SUM(f.sales_amount) AS revenue ,
				SUM(f.profit) AS profit
		FROM gold.fact_sales AS f
		LEFT JOIN gold.dim_date AS d
		ON f.order_date = d.date_key
		WHERE order_status <> 'Cancelled'
		GROUP BY d.year , d.month_name , d.month_number 
)
SELECT year , month_number , month_name , revenue , profit ,
		ROUND(100.0 * profit / NULLIF(revenue , 0) , 2) AS profit_margin ,
		ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY year , month_number)) /
				NULLIF(LAG(revenue) OVER (ORDER BY year , month_number) ,0) , 2) AS MOM_growth
FROM monthly 
ORDER BY year , month_number;

SELECT * FROM gold.revenue_profit_MOM;
--------------------------------------------------------------------------------------
--Which categories and products earn the most revenue vs. the most profit?

CREATE VIEW gold.top_categories_products AS
WITH products AS (
		SELECT p.product_name , p.product_category ,
				SUM(f.quantity) AS units_sold,
				SUM(f.sales_amount) AS revenue ,
				SUM(f.profit) AS profit ,
				ROUND(100.0 * SUM(f.profit) / NULLIF(SUM(f.sales_amount),0) , 2) AS profit_margin
		FROM gold.fact_sales AS f
		LEFT JOIN gold.dim_product AS p
		ON f.product_id = p.product_id
		WHERE order_status <> 'Cancelled'
		GROUP BY p.product_category , p.product_subcategory , p.product_name
		ORDER BY p.product_category , p.product_subcategory , p.product_name
) 
SELECT *,
		RANK() OVER(ORDER BY revenue DESC) AS revenue_rank,
		RANK() OVER(ORDER BY profit DESC) AS profit_rank
FROM products
ORDER BY revenue_rank;

SELECT * FROM gold.top_categories_products LIMIT 10;
--------------------------------------------------------------------------------------
--Which countries and stores drive the most revenue vs. the most profit?

CREATE VIEW gold.top_countries_stores AS
WITH countries_stores AS (
		SELECT s.store_name ,s.country, s.city,
				COUNT(transaction_id) AS transaction_counts ,
				SUM(f.quantity) AS units_sold,
				SUM(f.sales_amount) AS revenue ,
				SUM(f.profit) AS profit ,
				ROUND(100.0 * SUM(f.profit) / NULLIF(SUM(f.sales_amount),0) , 2) AS profit_margin
		FROM gold.fact_sales AS f
		LEFT JOIN gold.dim_store AS s
		ON f.store_id = s.store_id
		WHERE order_status <> 'Cancelled'
		GROUP BY s.store_name ,s.country, s.city
) 
SELECT *,
		RANK() OVER(ORDER BY revenue DESC) AS revenue_rank,
		RANK() OVER(ORDER BY profit DESC) AS profit_rank
FROM countries_stores
ORDER BY revenue_rank;

SELECT * FROM gold.top_countries_stores
LIMIT 5;
-------------------------------------------------------------------------------------------------
--Which order channel drive the best performance ?

CREATE VIEW sales_channel_comparison AS
SELECT sales_channel , 
		COUNT(*) AS transactions_count,
		SUM(sales_amount) AS revenue ,
		SUM(profit) AS profit,
		ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales_amount),0) , 2) AS profit_margin,
		ROUND(SUM(sales_amount) / NULLIF(COUNT(*) ,0) ,2) AS avg_order_value
FROM gold.fact_sales
WHERE order_status <> 'Cancelled'
GROUP BY sales_channel
ORDER BY profit_margin DESC;

SELECT * FROM sales_channel_comparison;
-------------------------------------------------------------------------------------------------
-- What is Return rate by category and by reason?
--Return rate by category (rate = returned transactions / all transactions)
SELECT 	p.product_category,
		COUNT(*) AS transactions,
		COUNT(f.return_flag) FILTER(WHERE f.return_flag = 'Yes') AS returned_transactions,
		ROUND(100.0* COUNT(f.return_flag) FILTER(WHERE f.return_flag = 'Yes') / COUNT(*) , 2)AS return_rate,
		SUM(f.sales_amount) FILTER(WHERE f.return_flag ='Yes') AS returned_revenue,
		RANK() OVER(ORDER BY COUNT(*) FILTER(WHERE f.return_flag='Yes')::NUMERIC / COUNT(*) DESC) AS returned_rank
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_product AS p
ON f.product_id = p.product_id
WHERE f.order_status <> 'Cancelled'
GROUP BY p.product_category
ORDER BY returned_rank;

--Return rate by reason 
SELECT 
	   COALESCE(return_reason , 'Not Spascified') AS return_reason,
	   COUNT(*) AS returned_transactions ,
	   SUM(sales_amount) AS returned_revenue,
	   ROUND(AVG(sales_amount) ,2) AS avg_returned_revenue
FROM gold.fact_sales
WHERE return_flag = 'Yes' AND order_status <> 'Cancelled'
GROUP BY return_reason
ORDER BY returned_transactions;
-------------------------------------------------------------------------------------------------
-- TOP 10 Customer by revenue
WITH customer AS (
SELECT f.customer_id , 
	   c.customer_name ,
	   COUNT(*) AS transactions,
	   SUM(f.sales_amount) AS revenue,
	   SUM(f.profit) AS profit,
	   MIN(f.order_date) AS first_order,
	   MAX(f.order_date) AS last_order
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customer AS c 
ON f.customer_id = c.customer_id
WHERE f.order_status <> 'Cancelled'
GROUP BY f.customer_id , c.customer_name
ORDER BY f.customer_id)
SELECT RANK() OVER(ORDER BY revenue DESC) AS revenue_rank,
	   customer_id , customer_name ,transactions,revenue,profit,
	   ROUND(100.0 * revenue / SUM(revenue) OVER(),2) AS revenue_share,
	   first_order , last_order	   
FROM customer
LIMIT 10 ;
-----------------------------------
-- RFM Cutomers Segmentation 
WITH base AS (
    SELECT customer_id,
           (SELECT MAX(order_date) FROM gold.fact_sales) - MAX(order_date) AS recency_days,
           COUNT(*) AS frequency,
           SUM(sales_amount) AS monetary
    FROM gold.fact_sales
    WHERE order_status IS DISTINCT FROM 'Cancelled'
    GROUP BY customer_id
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,   -- 5 = bought most recently
           NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score,   -- 5 = buys most often
           NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score    -- 5 = spends the most
    FROM base
),
seg AS (
    SELECT *,
           CASE WHEN recency_score >= 4 AND frequency_score >= 4 THEN 'Champions'
                WHEN frequency_score >= 4                  THEN 'Loyal'
                WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New / Promising'
                WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
                WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Lost'
                ELSE 'Regular'
           END AS rfm_segment
    FROM scored
)
SELECT rfm_segment,
       COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customers_pct,
       SUM(monetary) AS revenue,
       ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 2) AS revenue_pct,
       ROUND(AVG(recency_days)) AS avg_recency_days,
       ROUND(AVG(frequency), 1) AS avg_frequency
FROM seg
GROUP BY rfm_segment
ORDER BY revenue DESC;	
--------------------------------------------------------------------------------------------
--Does delivery time affect product rating and returns?
--ALL about delivery days and return rate for each product
SELECT p.product_name, p.product_category,
	   COUNT(*) AS transactions,
	   SUM(f.sales_amount) AS revenue,
	   SUM(f.profit) AS profit,
	   ROUND(AVG(f.delivery_days) ,2) AS avg_delivery_days,
	   COUNT(*) FILTER (WHERE f.return_flag = 'Yes') AS returned_transactions,
	   ROUND(100.0* COUNT(f.return_flag) FILTER(WHERE f.return_flag = 'Yes') / COUNT(*) , 2)AS return_rate,
	   ROUND(AVG(customer_rating) , 2) AS avg_customer_rating
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_product AS p
ON f.product_id = p.product_id 
WHERE f.order_status <> 'Cancelled'
GROUP BY p.product_name, p.product_category
ORDER BY avg_delivery_days DESC;
-- All abount delivery days
SELECT MIN(delivery_days) AS min_days,
       MAX(delivery_days) AS max_days,
       ROUND(AVG(delivery_days), 1) AS avg_days,
       COUNT(*) FILTER (WHERE delivery_days IS NULL) AS missing_days,
       COUNT(*) FILTER (WHERE delivery_days = 0) AS zero_days,
       COUNT(*) FILTER (WHERE customer_rating IS NULL) AS missing_rating
FROM gold.fact_sales
WHERE order_status IS DISTINCT FROM 'Cancelled';   
-- Convert delivery days to categories range 
SELECT CASE WHEN delivery_days IS NULL THEN 'Unknown'
            WHEN delivery_days <= 2    THEN '1) 0-2 days'
            WHEN delivery_days <= 5    THEN '2) 3-5 days'
            WHEN delivery_days <= 8    THEN '3) 6-8 days'
            ELSE                            '4) 9+ days'
       END AS delivery_bucket,
       COUNT(*)  AS transactions,
       COUNT(customer_rating) AS rated_transactions,
       ROUND(AVG(customer_rating), 2) AS avg_rating,
       ROUND(100.0 * COUNT(*) FILTER (WHERE return_flag = 'Yes') / COUNT(*), 2)  AS return_rate_pct,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_of_transactions_pct
FROM gold.fact_sales
WHERE order_status IS DISTINCT FROM 'Cancelled'
GROUP BY 1
ORDER BY 1;
-- delivery days rating and return rating for shipping methods
SELECT COALESCE(shipping_method, 'Unknown')AS shipping_method,
       COUNT(*)AS transactions,
       ROUND(AVG(delivery_days), 1) AS avg_delivery_days,
       ROUND(AVG(customer_rating), 2) AS avg_rating,
       ROUND(100.0 * COUNT(*) FILTER (WHERE return_flag = 'Yes') / COUNT(*), 2)  AS return_rate_pct
FROM gold.fact_sales
WHERE order_status IS DISTINCT FROM 'Cancelled'
GROUP BY 1
ORDER BY avg_delivery_days;

---- delivery days rating and return rating for payment methods
SELECT COALESCE(payment_method, 'Unknown')AS payment_method,
       COUNT(*)AS transactions,
       ROUND(AVG(delivery_days), 1) AS avg_delivery_days,
       ROUND(AVG(customer_rating), 2) AS avg_rating,
       ROUND(100.0 * COUNT(*) FILTER (WHERE return_flag = 'Yes') / COUNT(*), 2)  AS return_rate_pct
FROM gold.fact_sales
WHERE order_status IS DISTINCT FROM 'Cancelled'
GROUP BY 1
ORDER BY 2 DESC;