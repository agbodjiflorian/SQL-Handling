/* SELECT * FROM clean_weekly_sales */ 

/* B. Data Exploration */

-- 1- What day of the week is used for each week_date value?
SELECT DISTINCT TO_CHAR(week_date, 'day')
FROM clean_weekly_sales

-- 2- What range of week numbers are missing from the dataset?

WITH RECURSIVE cte as (
	SELECT 1 as weekk
),
sec as (
	SELECT weekk FROM cte
	UNION
	SELECT weekk + 1 as week FROM sec WHERE weekk < 52
)

SELECT c.weekk as missing_week
FROM (
	SELECT DISTINCT a.week_number, b.weekk
	FROM clean_weekly_sales a
	RIGHT JOIN (
		SELECT * FROM sec
	) b
		ON a.week_number = b.weekk
	ORDER BY a.week_number
) c
WHERE c.week_number IS NULL

-- 3- How many total transactions were there for each year in the dataset?

SELECT calendar_year, SUM(transactions) as total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year

-- 4- What is the total sales for each region for each month?

SELECT region, month_number, SUM(sales) as total_sales
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY region

-- 5-  What is the total count of transactions for each platform?

SELECT platform, SUM(transactions) as total_count
FROM clean_weekly_sales
GROUP BY platform

-- 6- What is the percentage of sales for Retail vs Shopify for each month?

SELECT c.platform, c.month_number, c.calendar_year, c.sales_month_platform, c.total_sales_month,
	ROUND((c.sales_month_platform::numeric*100/c.total_sales_month) , 2) as percentage
FROM (
	SELECT a.platform, a.month_number, a.calendar_year, SUM(a.sales) as sales_month_platform, b.total_sales_month
	FROM clean_weekly_sales a
	LEFT JOIN (
		SELECT month_number, calendar_year, SUM(sales) as total_sales_month
		FROM clean_weekly_sales
		GROUP BY month_number, calendar_year
	) b
		ON a.month_number = b.month_number AND a.calendar_year = b.calendar_year
	GROUP BY a.platform, a.month_number, a.calendar_year, b.total_sales_month
	ORDER BY a.month_number
) c
GROUP BY c.platform, c.month_number, c.calendar_year, c.sales_month_platform, c.total_sales_month
ORDER BY c.calendar_year, c.month_number

-- 7- What is the percentage of sales by demographic for each year in the dataset?

SELECT c.calendar_year, c.demographic, c.sales_dem_year, c.total_sales, 
	ROUND((c.sales_dem_year::numeric*100/c.total_sales), 2) as percentage
FROM (
	SELECT a.calendar_year, a.demographic, SUM(a.sales) as sales_dem_year, b.total_sales
	FROM clean_weekly_sales a
	LEFT JOIN (
		SELECT calendar_year, SUM(sales) as total_sales
		FROM clean_weekly_sales
		GROUP BY calendar_year
	) b
		ON a.calendar_year = b.calendar_year
	GROUP BY a.calendar_year, a.demographic, b.total_sales
	ORDER BY a.calendar_year
) c
GROUP BY c.calendar_year, c.demographic, c.sales_dem_year, c.total_sales

-- 8- Which age_band and demographic values contribute the most to Retail sales?

SELECT a.age_band, a.demographic, a.total
FROM (
	SELECT age_band, demographic, SUM(sales) as total
	FROM clean_weekly_sales
	WHERE platform = 'Retail'
	GROUP BY age_band, demographic
) a
GROUP BY a.age_band, a.demographic, a.total
ORDER BY a.total DESC

/* 9- Can we use the avg_transaction column to find the average transaction size 
	for each year for Retail vs Shopify? If not - how would you calculate it instead? */
	
SELECT calendar_year, platform, ROUND(AVG(avg_transaction), 2)
FROM clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year
