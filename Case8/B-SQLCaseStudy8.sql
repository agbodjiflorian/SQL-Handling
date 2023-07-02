/*
SELECT * FROM interest_map LIMIT 5
SELECT * FROM interest_metrics LIMIT 5
SELECT * FROM json_data LIMIT 5
*/

/* B. Interest Analysis */

/*
-- 1- Which interests have been present in all month_year dates in our dataset?

WITH cte as (
	SELECT month_year, interest_id
	FROM interest_metrics
	GROUP BY month_year, interest_id
)

SELECT b.interest_id
FROM (
	SELECT DISTINCT a.interest_id, COUNT(DISTINCT a.month_year) as nb_appearence
	FROM cte a
	GROUP BY a.interest_id
) b
WHERE b.nb_appearence = (SELECT COUNT(DISTINCT month_year) FROM cte)
ORDER BY b.interest_id::int

/* 2- Using this same total_months measure 
	- calculate the cumulative percentage of all records starting at 14 months 
	- which total_months value passes the 90% cumulative percentage value? */

WITH cte as (
	SELECT month_year, interest_id
	FROM interest_metrics
	GROUP BY month_year, interest_id
),
cte1 as (
	SELECT b.nb_appearence, COUNT(b.interest_id) as nb_count
	FROM (
		SELECT DISTINCT a.interest_id, COUNT(a.month_year) as nb_appearence
		FROM cte a
		GROUP BY a.interest_id
	) b
	GROUP BY b.nb_appearence
	ORDER BY b.nb_appearence DESC
)

SELECT nb_appearence, nb_count, 
	SUM(nb_count) OVER(ORDER BY nb_appearence DESC) as cumulative_nb_count,
	ROUND(100*(SUM(nb_count) OVER(ORDER BY nb_appearence DESC))::numeric/
		  (SELECT SUM(nb_count) FROM cte1), 2) as cumulative_percentage
FROM cte1

/* 3- If we were to remove all interest_id values which are lower than 
	the total_months value we found in the previous question 
	- how many total data points would we be removing? */
*/
WITH cte as (
	SELECT month_year, interest_id
	FROM interest_metrics
	GROUP BY month_year, interest_id
),
cte1 as (
	SELECT b.nb_appearence, COUNT(b.interest_id) as nb_count
	FROM (
		SELECT DISTINCT a.interest_id, COUNT(a.month_year) as nb_appearence
		FROM cte a
		GROUP BY a.interest_id
	) b
	GROUP BY b.nb_appearence
	ORDER BY b.nb_appearence DESC
),
cte2 as (
	SELECT nb_appearence, nb_count, 
		SUM(nb_count) OVER(ORDER BY nb_appearence DESC) as cumulative_nb_count,
		ROUND(100*(SUM(nb_count) OVER(ORDER BY nb_appearence DESC))::numeric/
			  (SELECT SUM(nb_count) FROM cte1), 2) as cumulative_percentage
	FROM cte1
)

SELECT COUNT(d.interest_id) as nb_to_remove
FROM (
	SELECT b.interest_id, b.nb_appearence, c.cumulative_percentage
	FROM (
		SELECT DISTINCT a.interest_id, COUNT(DISTINCT a.month_year) as nb_appearence
		FROM cte a
		GROUP BY a.interest_id
	) b
	JOIN cte2 c ON b.nb_appearence = c.nb_appearence
	ORDER BY b.interest_id::int
) d
WHERE d.cumulative_percentage <= 90



