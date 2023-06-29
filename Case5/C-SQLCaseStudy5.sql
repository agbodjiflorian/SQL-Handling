/* SELECT * FROM clean_weekly_sales */ 

/* C. Before & After Analysis */

/* 1- What is the total sales for the 4 weeks before and after 2020-06-15? 
	What is the growth or reduction rate in actual values and percentage of sales? */
	
WITH total_sales_four_weeks_before as (
	SELECT SUM(sales) as total_sales_before
	FROM clean_weekly_sales
	WHERE week_number BETWEEN (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))-4)
				  AND (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))-1)
),
total_sales_four_weeks_after as (
	SELECT SUM(sales) as total_sales_after
	FROM clean_weekly_sales
	WHERE week_number BETWEEN DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))
				  AND (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))+3)
)

SELECT total_sales_before, total_sales_after, 
	ROUND((total_sales_after - total_sales_before)::numeric*100/total_sales_before, 2)
FROM total_sales_four_weeks_before, total_sales_four_weeks_after

-- 2- What about the entire 12 weeks before and after?

WITH total_sales_twelve_weeks_before as (
	SELECT SUM(sales) as total_sales_before
	FROM clean_weekly_sales
	WHERE week_number BETWEEN (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))-12)
				  AND (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))-1)
),
total_sales_twelve_weeks_after as (
	SELECT SUM(sales) as total_sales_after
	FROM clean_weekly_sales
	WHERE week_number BETWEEN DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))
				  AND (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))+11)
)

SELECT total_sales_before, total_sales_after, 
	ROUND((total_sales_after - total_sales_before)::numeric*100/total_sales_before, 2)
FROM total_sales_twelve_weeks_before, total_sales_twelve_weeks_after

/* 3- How do the sale metrics for these 2 periods before and after 
	compare with the previous years in 2018 and 2019? */

-- 4 weeks period
WITH total_sales_four_weeks_before as (
	SELECT calendar_year, SUM(sales) as total_sales_before
	FROM clean_weekly_sales
	WHERE week_number BETWEEN (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))-4)
				  AND (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))-1)
	GROUP BY calendar_year
),
total_sales_four_weeks_after as (
	SELECT calendar_year, SUM(sales) as total_sales_after
	FROM clean_weekly_sales
	WHERE week_number BETWEEN DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))
				  AND (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))+3)
	GROUP BY calendar_year
)

SELECT a.calendar_year, a.total_sales_before, b.total_sales_after, 
	ROUND((b.total_sales_after - a.total_sales_before)::numeric*100/a.total_sales_before, 2) 
FROM total_sales_four_weeks_before a
JOIN (
	SELECT * FROM total_sales_four_weeks_after
) b
	ON a.calendar_year = b.calendar_year
GROUP BY a.calendar_year, a.total_sales_before, b.total_sales_after

-- 12 weeks period

WITH total_sales_twelve_weeks_before as (
	SELECT calendar_year, SUM(sales) as total_sales_before
	FROM clean_weekly_sales
	WHERE week_number BETWEEN (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))-12)
				  AND (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))-1)
	GROUP BY calendar_year
),
total_sales_twelve_weeks_after as (
	SELECT calendar_year, SUM(sales) as total_sales_after
	FROM clean_weekly_sales
	WHERE week_number BETWEEN DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))
				  AND (DATE_PART('week', TO_DATE('2020-06-15', 'YYYY-MM-DD'))+11)
	GROUP BY calendar_year
)

SELECT a.calendar_year, a.total_sales_before, b.total_sales_after, 
	ROUND((b.total_sales_after - a.total_sales_before)::numeric*100/a.total_sales_before, 2) 
FROM total_sales_twelve_weeks_before a
JOIN (
	SELECT * FROM total_sales_twelve_weeks_after
) b
	ON a.calendar_year = b.calendar_year
GROUP BY a.calendar_year, a.total_sales_before, b.total_sales_after
