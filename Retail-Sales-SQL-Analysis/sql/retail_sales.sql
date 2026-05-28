/**********************************************************************************************
*   RETAIL SALES ANALYSIS PROJECT
*   Author: MERSIMOY GURMU
*   Description:
*       This script loads, cleans, and analyzes a retail sales dataset.
*       It follows a real-world data workflow:
*           1. Load and inspect data
*           2. Clean and standardize values
*           3. Fix duplicates, dates, and incorrect totals
*           4. Generate KPIs and business insights
**********************************************************************************************/

#==============================================================================================================
#                                           STEP 1: LOAD THE DATA
#==============================================================================================================

-- Look at the first 20 rows to confirm the data loaded correctly
SELECT * 
FROM retail_sales
LIMIT 20;


#==============================================================================================================
#                                           STEP 2: CLEAN THE DATA
#==============================================================================================================
-- Cleaning tasks include:
--   • Removing duplicate rows
--   • Standardizing messy text values (Region names)
--   • Fixing mixed date formats
--   • Correcting incorrect Total_Price values
--   • Checking for missing values


/**********************************************************************************************
*   PART A: REMOVE DUPLICATES
**********************************************************************************************/

-- Check how many duplicate Order_ID values exist
SELECT 
    Order_ID,
    COUNT(*) AS count_duplicates
FROM retail_sales
GROUP BY Order_ID
HAVING COUNT(*) > 1;

-- Add a temporary auto-increment column to uniquely identify each row
ALTER TABLE retail_sales
ADD COLUMN temp_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

-- Delete duplicate rows by keeping the row with the smallest temp_id
SET SQL_SAFE_UPDATES = 0;

DELETE t1
FROM retail_sales t1
JOIN retail_sales t2
    ON t1.Order_ID = t2.Order_ID
   AND t1.temp_id > t2.temp_id;

SET SQL_SAFE_UPDATES = 1;

-- Remove the temporary column now that duplicates are gone
ALTER TABLE retail_sales
DROP COLUMN temp_id;

-- Verify duplicates are removed
SELECT Order_ID, COUNT(*)
FROM retail_sales
GROUP BY Order_ID
HAVING COUNT(*) > 1;


/**********************************************************************************************
*   PART B: STANDARDIZE REGION NAMES
**********************************************************************************************/

-- Check the unique region values before cleaning
SELECT DISTINCT Region
FROM retail_sales;

SET SQL_SAFE_UPDATES = 0;

-- Convert region names to proper case (e.g., west → West)
UPDATE retail_sales
SET Region = CONCAT(
        UPPER(LEFT(Region, 1)),
        LOWER(SUBSTRING(Region, 2))
    );

SET SQL_SAFE_UPDATES = 1;

-- Verify the update
SELECT DISTINCT Region
FROM retail_sales;


/**********************************************************************************************
*   PART C: FIX MIXED DATE FORMATS
**********************************************************************************************/

-- Add a new clean DATE column
ALTER TABLE retail_sales
ADD COLUMN Clean_Order_Date DATE;

-- Convert both formats (YYYY-MM-DD and YYYY/MM/DD) into a proper DATE
UPDATE retail_sales
SET Clean_Order_Date =
    CASE
        WHEN Order_Date LIKE '%/%' THEN STR_TO_DATE(Order_Date, '%Y/%m/%d')
        WHEN Order_Date LIKE '%-%' THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
    END;

-- Check the conversion
SELECT Order_Date, Clean_Order_Date
FROM retail_sales
LIMIT 20;

-- Remove the old messy column
ALTER TABLE retail_sales
DROP COLUMN Order_Date;

-- Rename the clean column to Order_Date
ALTER TABLE retail_sales
CHANGE COLUMN Clean_Order_Date Order_Date DATE;


/**********************************************************************************************
*   PART D: FIX INCORRECT TOTAL PRICE VALUES
**********************************************************************************************/

-- Identify rows where Total_Price does not match Quantity × Unit_Price
SELECT *
FROM retail_sales
WHERE Total_Price <> Quantity * Unit_Price;

-- Correct the incorrect totals
SET SQL_SAFE_UPDATES = 0;

UPDATE retail_sales
SET Total_Price = Quantity * Unit_Price
WHERE Total_Price <> Quantity * Unit_Price;

SET SQL_SAFE_UPDATES = 1;

-- Verify the correction
SELECT *
FROM retail_sales
WHERE Total_Price <> Quantity * Unit_Price;


/**********************************************************************************************
*   PART E: CHECK FOR MISSING VALUES
**********************************************************************************************/

SELECT *
FROM retail_sales
WHERE 
    Order_ID IS NULL OR
    Order_Date IS NULL OR
    Customer_ID IS NULL OR
    Product IS NULL OR
    Category IS NULL OR
    Region IS NULL OR
    Quantity IS NULL OR
    Unit_Price IS NULL OR
    Total_Price IS NULL OR
    Payment_Method IS NULL;


#==============================================================================================================
#                                           STEP 3: ANALYSIS & KPIs
#==============================================================================================================

/**********************************************************************************************
*   PART A: CORE KPIs
**********************************************************************************************/

-- Total revenue generated
SELECT SUM(Total_Price) AS Total_Revenue
FROM retail_sales;

-- Total number of orders
SELECT COUNT(*) AS Total_Orders
FROM retail_sales;

-- Average amount spent per order
SELECT ROUND(AVG(Total_Price), 2) AS Average_Order_Value
FROM retail_sales;

-- Total units sold across all products
SELECT SUM(Quantity) AS Total_Units_Sold
FROM retail_sales;


/**********************************************************************************************
*   PART B: REVENUE BREAKDOWN
**********************************************************************************************/

-- Revenue by product category
SELECT Category, SUM(Total_Price) AS Revenue
FROM retail_sales
GROUP BY Category
ORDER BY Revenue DESC;

-- Revenue by region
SELECT Region, SUM(Total_Price) AS Revenue
FROM retail_sales
GROUP BY Region
ORDER BY Revenue DESC;

-- Revenue by payment method
SELECT Payment_Method, SUM(Total_Price) AS Revenue
FROM retail_sales
GROUP BY Payment_Method
ORDER BY Revenue DESC;


/**********************************************************************************************
*   PART C: TOP PERFORMERS
**********************************************************************************************/

-- Top 10 best-selling products by revenue
SELECT Product, SUM(Total_Price) AS Revenue
FROM retail_sales
GROUP BY Product
ORDER BY Revenue DESC
LIMIT 10;

-- Top 10 customers by total spending
SELECT Customer_ID, SUM(Total_Price) AS Total_Spent
FROM retail_sales
GROUP BY Customer_ID
ORDER BY Total_Spent DESC
LIMIT 10;


/**********************************************************************************************
*   PART D: TIME-BASED TRENDS
**********************************************************************************************/

-- Monthly revenue trend
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') AS Month,
    SUM(Total_Price) AS Revenue
FROM retail_sales
GROUP BY Month
ORDER BY Month;

-- Daily revenue trend
SELECT 
    Order_Date,
    SUM(Total_Price) AS Revenue
FROM retail_sales
GROUP BY Order_Date
ORDER BY Order_Date;
