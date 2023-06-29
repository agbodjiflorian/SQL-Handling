/* SELECT * FROM clean_weekly_sales */ 

/* D. Bonus Question */

/* Which areas of the business have the highest negative impact in 
	sales metrics performance in 2020 for the 12 week before and after period? */
	
-- 12 weeks period
-- For Region

WITH total_sales_twelve_weeks_before as (
	SELECT region, SUM(sales) as total_sales_before
	FROM clean_weekly_sales
	WHERE week_number BETWEEN (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))-12)
				  AND (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))-1)
				  AND calendar_year = 2020
	GROUP BY region
),
total_sales_twelve_weeks_after as (
	SELECT region, SUM(sales) as total_sales_after
	FROM clean_weekly_sales
	WHERE week_number BETWEEN DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))
				  AND (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))+11)
				AND calendar_year = 2020
	GROUP BY region
)

SELECT a.region, a.total_sales_before, b.total_sales_after, 
	b.total_sales_after - a.total_sales_before as variance,
	ROUND(100*(b.total_sales_after - a.total_sales_before)::numeric/a.total_sales_before, 2) 
FROM total_sales_twelve_weeks_before a
JOIN (
	SELECT * FROM total_sales_twelve_weeks_after
) b
	ON a.region = b.region
GROUP BY a.region, a.total_sales_before, b.total_sales_after
