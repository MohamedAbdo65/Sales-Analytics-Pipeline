--Before start we build a database schema and but layers also load data from sales transactions csv file

CREATE DATABASE salesdwh; --create database
CREATE SCHEMA bronze; --create schema layers bronze silver gold
CREATE SCHEMA silver;
CREATE SCHEMA gold;


-- drop table id exixts 
DROP TABLE IF EXISTS bronze.salesinfo;
--create bronze salesinfo table
CREATE TABLE bronze.salesinfo(
		Transaction_ID VARCHAR(30),
		Order_ID VARCHAR(20),
		Customer_ID VARCHAR(20),
		Customer_Name VARCHAR(50),
		Customer_Age NUMERIC,
		Customer_Gender VARCHAR(10),
		Customer_Segment VARCHAR(30),
		Order_Date DATE ,
		Order_Time TIME,
		Sales_Channel VARCHAR(30),
		Store_ID VARCHAR(20),
		Store_Name VARCHAR(50),
		Country VARCHAR(30),
		Region VARCHAR(30),
		City VARCHAR(30),
		Product_ID VARCHAR(20),
		Product_Name VARCHAR(30),
		Product_Category VARCHAR(30),
		Product_Subcategory VARCHAR(30),
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
		Inventory_Level NUMERIC,
		Order_Year INTEGER
);  

SELECT * FROM bronze.salesinfo;   --check data
SELECT COUNT(*) FROM bronze.salesinfo;  --check for rows count