CREATE OR REPLACE PROCEDURE GOLD.CREATE_GOLD () LANGUAGE PLPGSQL AS $$
BEGIN

	RAISE NOTICE '===========================================';
	RAISE NOTICE 'Creating Gold Layer';
	RAISE NOTICE '============================================';
--Create Fact_Sales Table
CREATE TABLE IF NOT EXISTS gold.fact_sales(
		Transaction_ID VARCHAR(30),
		Order_Date DATE ,
		Order_Time TIME,
		Customer_ID VARCHAR(30),
		Product_ID VARCHAR(30),
		Store_ID VARCHAR(30),
		Sales_Channel VARCHAR(30),
		Quantity INTEGER,
		Unit_Price NUMERIC,
		Discount_Percentage NUMERIC,
		Sales_Amount NUMERIC,
		Cost_Amount NUMERIC,
		Profit NUMERIC,
		Payment_Method VARCHAR(30),
		Order_Status VARCHAR(30),
		Shipping_Method VARCHAR(30),
		Delivery_Days NUMERIC,
		Return_Flag VARCHAR(20),
		Return_Reason VARCHAR(100),
		Sales_Representative VARCHAR(50),
		Promotion_Code VARCHAR(30),
		Customer_Rating NUMERIC,
		Inventory_Level NUMERIC
		);
		
--Create dim_product Table
CREATE TABLE IF NOT EXISTS gold.dim_product(
		Product_ID VARCHAR(20),
		Product_Name VARCHAR(30),
		Product_Category VARCHAR(30),
		Product_Subcategory VARCHAR(30));
		
--Create dim_store Table
CREATE TABLE IF NOT EXISTS gold.dim_store(
		Store_ID VARCHAR(20),
		Store_Name VARCHAR(50),
		Country VARCHAR(30),
		Region VARCHAR(30),
		City VARCHAR(30));
		
--Create dim_customer Table
CREATE TABLE IF NOT EXISTS gold.dim_customer(
		Customer_ID VARCHAR(20) ,
		Customer_Name VARCHAR(50),
		Customer_Age INTEGER,
		Customer_Gender VARCHAR(10)
		);
		
--Create dim_date Table	
CREATE TABLE IF NOT EXISTS gold.dim_date(
		date_key DATE  ,
		Year INTEGER,
		quarter_name VARCHAR(10),
		quarter_number INTEGER,
		month_name VARCHAR(15),
		month_number INTEGER,
		weekday_name VARCHAR(20),
		weekday_number INTEGER);
	--but PK and FK for each table
	ALTER TABLE gold.dim_date     ADD PRIMARY KEY (date_key);
	ALTER TABLE gold.dim_product  ADD PRIMARY KEY (Product_ID);
	ALTER TABLE gold.dim_store    ADD PRIMARY KEY (Store_ID);
	ALTER TABLE gold.dim_customer ADD PRIMARY KEY (customer_id);
	 
	ALTER TABLE gold.fact_sales
	    ADD PRIMARY KEY (transaction_id),
	    ADD FOREIGN KEY (Order_Date)    REFERENCES gold.dim_date(date_key),
	    ADD FOREIGN KEY (Product_ID)  REFERENCES gold.dim_product(Product_ID),
	    ADD FOREIGN KEY (Store_ID)    REFERENCES gold.dim_store(Store_ID),
	    ADD FOREIGN KEY (Customer_ID) REFERENCES gold.dim_customer(Customer_ID);
	 --createing indexes for tabels
	CREATE INDEX idx_fact_date     ON gold.fact_sales (Order_Date);
	CREATE INDEX idx_fact_product  ON gold.fact_sales (Product_ID);
	CREATE INDEX idx_fact_store    ON gold.fact_sales (Store_ID);
	CREATE INDEX idx_fact_customer ON gold.fact_sales (Customer_ID);
	RAISE NOTICE '===========================================';
    RAISE NOTICE 'Creating Gold Tables is Completed';

END;
$$;

CALL GOLD.CREATE_GOLD ()