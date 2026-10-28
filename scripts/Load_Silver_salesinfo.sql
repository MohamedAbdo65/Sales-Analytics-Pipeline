CREATE OR REPLACE PROCEDURE SILVER.LOAD_SILVER () LANGUAGE 'plpgsql' AS $BODY$
DECLARE
		start_time TIMESTAMP;
		end_time TIMESTAMP;
BEGIN
	start_time := clock_timestamp();
	
	RAISE NOTICE '===========================================';
	RAISE NOTICE 'Loading Silver Layer';
	RAISE NOTICE '============================================';

	--load sales_info table in silver layer
	RAISE NOTICE 'Truncating Table : silver.salesinfo';
	TRUNCATE TABLE silver.salesinfo;
	RAISE NOTICE 'Insert values in sales info table';
	INSERT INTO silver.salesinfo(
			Transaction_ID,
			Order_ID,
			Customer_ID,
			Customer_Name,
			Customer_Age,
			Customer_Gender,
			Customer_Segment,
			Order_Date,
			Order_Time,
			Sales_Channel,
			Store_ID,
			Store_Name,
			Country,
			Region,
			City,
			Product_ID,
			Product_Name,
			Product_Category,
			Product_Subcategory,
			Quantity,
			Unit_Price,
			Discount_Percentage,
			Sales_Amount,
			Cost_Amount,
			Profit,
			Payment_Method,
			Order_Status,
			Shipping_Method,
			Delivery_Days,
			Return_Flag,
			Return_Reason,
			Sales_Representative,
			Promotion_Code,
			Customer_Rating,
			Inventory_Level,
			Order_Year
	)
	SELECT 
		transaction_id,
        order_id,
        customer_id,
        INITCAP(TRIM(customer_name))AS customer_name,
        customer_age,
		CASE WHEN customer_gender IN ('male' ,'Male') THEN 'Male'
			WHEN customer_gender IN('Female' , 'FEMALE') THEN 'Female'
			ELSE 'N/A'
		END AS customer_gender,
		INITCAP(TRIM(Customer_Segment)) AS Customer_Segment,
        order_date,
        order_time,
        INITCAP(TRIM(sales_channel)) AS sales_channel,
        store_id,
        INITCAP(TRIM(store_name)) AS store_name,
        INITCAP(TRIM(country)) AS country,
        INITCAP(TRIM(region)) AS region,
        INITCAP(TRIM(city)) AS city,
        product_id,
        COALESCE(NULLIF(TRIM(product_name), ''),
                 MAX(product_name) OVER (PARTITION BY product_id)) AS product_name,-- fill missing names from the same product_id
        INITCAP(TRIM(product_category))                 AS product_category,
        INITCAP(TRIM(product_subcategory))              AS product_subcategory,
        ROUND(sales_amount / unit_price , 0) AS quantity,
        unit_price,
        discount_percentage,
        sales_amount,
        cost_amount,
        sales_amount - cost_amount AS profit,       -- recalculated profit
        CASE WHEN payment_method IS NULL THEN 'Unknown'
			WHEN payment_method = 'DebitCard' THEN 'Debit Card'
			ELSE INITCAP(TRIM( payment_method))
		END AS payment_method,
        INITCAP(TRIM(order_status)) AS order_status,
        INITCAP(TRIM(shipping_method)) AS shipping_method,
        delivery_days,
        return_flag,
        INITCAP(TRIM(return_reason)) AS return_reason,
        INITCAP(TRIM(sales_representative)) AS sales_representative,
        CASE WHEN promotion_code IS NULL THEN 'No Promotion'
			 ELSE INITCAP(TRIM(promotion_code))
		 END AS promotion_code ,
        customer_rating,
        inventory_level,
		EXTRACT(YEAR FROM order_date) AS order_year
	FROM (
		SELECT * ,
				ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY order_date , order_time) AS col_flag
				FROM bronze.salesinfo
	)t
	WHERE col_flag = 1 ;
	
	end_time := clock_timestamp();
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Loading Silver Layer is Completed';
    RAISE NOTICE 'Total Load Duration: % seconds',
        ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::NUMERIC, 2);
    RAISE NOTICE '===========================================';

	EXCEPTION
	    WHEN OTHERS THEN
	        RAISE NOTICE '===========================================';
	        RAISE NOTICE 'ERROR OCCURRED DURING LOADING SILVER LAYER';
	        RAISE NOTICE 'Error Message: %', SQLERRM;
	        RAISE NOTICE 'Error Code: %', SQLSTATE;
	        RAISE NOTICE '===========================================';
	        RAISE;  -- re-throw so the failure isn't silent
END;
$BODY$;

CALL SILVER.LOAD_SILVER ();