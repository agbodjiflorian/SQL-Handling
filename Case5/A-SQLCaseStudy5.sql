/* SELECT * FROM weekly_sales LIMIT 10 */

-- A. Data Cleansing Steps

DROP TABLE IF EXISTS clean_weekly_sales

CREATE TABLE clean_weekly_sales AS
/*
ALTER TABLE weekly_sales
   ALTER COLUMN week_date TYPE DATE USING TO_DATE(week_date, 'DD-MM-YY')
*/
SELECT week_date, 
	DATE_PART('week', week_date) as week_number,
	DATE_PART('month', week_date) as month_number, DATE_PART('year', week_date) as calendar_year,
	region, platform, customer_type, 
	CASE
		WHEN segment IS NULL THEN 'unknown'
		WHEN segment = 'null' THEN 'unknown'
		ELSE segment
	END as segment,
	CASE
		WHEN SUBSTRING(segment, 2, 2) = '1' THEN 'Young Adults'
		WHEN SUBSTRING(segment, 2, 2) = '2' THEN 'Middle Aged'
		WHEN SUBSTRING(segment, 2, 2) = '3' OR LEFT(segment, 2) = '4' THEN 'Retirees'
		ELSE 'unknown'
	END as age_band,
	CASE
		WHEN SUBSTRING(segment, 1, 1) = 'C' THEN 'Couples'
		WHEN SUBSTRING(segment, 1, 1) = 'F' THEN 'Families'
		ELSE 'unknown'
	END as demographic,
	sales, transactions, ROUND((sales::numeric / transactions), 2) as avg_transaction
FROM weekly_sales

-- SELECT * FROM clean_weekly_sales
