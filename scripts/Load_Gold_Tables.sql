CREATE OR REPLACE PROCEDURE gold.load_gold() LANGUAGE 'plpgsql' AS $BODY$
DECLARE
		start_time TIMESTAMP;
		end_time TIMESTAMP;
BEGIN
	start_time := clock_timestamp();
	
	RAISE NOTICE '===========================================';
	RAISE NOTICE 'Loading Gold Layer Tables';
	RAISE NOTICE '============================================';
	RAISE NOTICE 'Truncating Tables before Loading';
	TRUNCATE TABLE gold.fact_sales,
                   gold.dim_customer,
                   gold.dim_date,
                   gold.dim_product,
                   gold.dim_store;
	--load dim_customer table in gold layer
	RAISE NOTICE 'Insert values in sales info table';
	INSERT INTO gold.dim_customer(
			customer_id,
			customer_name,
			customer_age,
			customer_gender
	)
	SELECT 
			customer_id,
			MODE() WITHIN GROUP(ORDER BY customer_name ) AS customer_name,
			MAX(customer_age) AS customer_age,
			MODE() WITHIN GROUP (ORDER BY customer_gender) AS customer_gender
	FROM silver.salesinfo
	GROUP BY customer_id;
	RAISE NOTICE 'loading gold dim customer table is Completed ';
	
	--load dim_date table in gold layer
	RAISE NOTICE 'Insert values in sales info table';
	INSERT INTO gold.dim_date(
			date_key,
			year,
			quarter_name,
			quarter_number,
			month_name,
			month_number,
			weekday_name,
			weekday_number
	)
	SELECT 	
			d ::DATE  AS date_key,
			EXTRACT(YEAR FROM d)::INT AS year,
			'Q' || EXTRACT(QUARTER FROM d)::INT AS quarter_name,
			EXTRACT(QUARTER FROM d)::INT AS quarter_number,
			TO_CHAR(d , 'Mon') AS month_name ,
			EXTRACT(MONTH FROM d)::INT AS month_number,
			TO_CHAR(d , 'Dy') AS weekday_name ,
			EXTRACT(DOW FROM d)::INT AS weekday_number
		
 FROM (
        SELECT (SELECT MIN(order_date) FROM silver.salesinfo) + g AS d
        FROM GENERATE_SERIES(
                 0,
                 (SELECT MAX(order_date) - MIN(order_date) FROM silver.salesinfo)) AS g
    ) AS cal;
    RAISE NOTICE 'gold.dim_date completed';
	
	--load dim_product table in gold layer
	RAISE NOTICE 'Insert values in sales info table';
	INSERT INTO gold.dim_product(
			product_id,
			product_name,
			product_category,
			product_subcategory
	)
	SELECT 
			product_id,
			MODE() WITHIN GROUP (ORDER BY product_name) AS product_name,
			MODE() WITHIN GROUP (ORDER BY product_category) AS product_category,
			MODE() WITHIN GROUP (ORDER BY product_subcategory) AS product_subcategory
	FROM  silver.salesinfo
	GROUP BY product_id;
	RAISE NOTICE 'loading gold dim product table is Completed ';
	
	--load dim_store table in gold layer
	RAISE NOTICE 'Insert values in sales info table';
	INSERT INTO gold.dim_store(
			store_id,
			store_name,
			country,
			region,
			city
	)
	SELECT  
			store_id,
			MODE() WITHIN GROUP (ORDER BY store_name) AS store_name,
			MODE() WITHIN GROUP (ORDER BY country) AS country,
			MODE() WITHIN GROUP (ORDER BY region) AS region,
			MODE() WITHIN GROUP (ORDER BY city) AS city
	FROM  silver.salesinfo
	GROUP BY store_id;
	RAISE NOTICE 'loading gold dim store table is Completed ';
	
		--load fact_sales table in gold layer
	RAISE NOTICE 'Insert values in sales info table';
	INSERT INTO gold.fact_sales(
		Transaction_ID ,
		Order_Date ,
		Order_Time ,
		Customer_ID ,
		Product_ID ,
		Store_ID ,
		Sales_Channel ,
		Quantity ,
		Unit_Price ,
		Discount_Percentage ,
		Sales_Amount ,
		Cost_Amount ,
		Profit ,
		Payment_Method ,
		Order_Status ,
		Shipping_Method ,
		Delivery_Days ,
		Return_Flag ,
		Return_Reason ,
		Sales_Representative ,
		Promotion_Code ,
		Customer_Rating ,
		Inventory_Level 
	)
	SELECT 
		Transaction_ID ,
		Order_Date ,
		Order_Time ,
		Customer_ID ,
		Product_ID ,
		Store_ID ,
		Sales_Channel ,
		Quantity ,
		Unit_Price ,
		Discount_Percentage ,
		Sales_Amount ,
		Cost_Amount ,
		Profit ,
		Payment_Method ,
		Order_Status ,
		Shipping_Method ,
		Delivery_Days ,
		Return_Flag ,
		Return_Reason ,
		Sales_Representative ,
		Promotion_Code ,
		Customer_Rating ,
		Inventory_Level 
		
	FROM silver.salesinfo;
	RAISE NOTICE 'loading gold fact sales table is Completed ';
	
	end_time := clock_timestamp();
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Loading gold Layer is Completed';
    RAISE NOTICE 'Total Load Duration: % seconds',
        ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::NUMERIC, 2);
    RAISE NOTICE '===========================================';

	EXCEPTION
	    WHEN OTHERS THEN
	        RAISE NOTICE '===========================================';
	        RAISE NOTICE 'ERROR OCCURRED DURING LOADING gold LAYER';
	        RAISE NOTICE 'Error Message: %', SQLERRM;
	        RAISE NOTICE 'Error Code: %', SQLSTATE;
	        RAISE NOTICE '===========================================';
	        RAISE;  -- re-throw so the failure isn't silent
END;
$BODY$;
