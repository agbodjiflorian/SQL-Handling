/*
SELECT * FROM interest_map LIMIT 5
SELECT * FROM interest_metrics LIMIT 5
SELECT * FROM json_data LIMIT 5
*/

/* A. Data Exploration and Cleansing */

/* 1- Update the interest_metrics table by modifying 
	the month_year column to be a date data type with the start of the month */

ALTER TABLE interest_metrics
   ALTER COLUMN month_year TYPE DATE USING TO_DATE(month_year, 'MM-YY')

/* 2- What is count of records in the interest_metrics 
	for each month_year value sorted in chronological order (earliest to latest) 
	with the null values appearing first? */

SELECT month_year, COUNT(CASE WHEN month_year IS NULL THEN date_trunc('month', now())::date ELSE month_year END)
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year NULLS FIRST

/* 3- What do you think we should do with these null values in the interest_metrics */

-- check the percentage of null values and drop them all if percentage is under 10%
SELECT ROUND(100 * COUNT(CASE WHEN month_year IS NULL THEN date_trunc('month', now())::date ELSE month_year END)::numeric/
			 (SELECT COUNT(*) FROM interest_metrics), 2) as null_percentage
FROM interest_metrics
WHERE month_year IS NULL

-- The percentage is under 10% then we can drop all the null values
DELETE FROM interest_metrics
WHERE month_year IS NULL

SELECT * FROM interest_metrics

/* 4- How many interest_id values exist in the interest_metrics table 
	but not in the interest_map table? What about the other way around? */

WITH nb_common_id as (
	SELECT COUNT(DISTINCT c.interest_id) as nb
	FROM (
		SELECT a.interest_id, b.id
		FROM interest_metrics a
		LEFT JOIN (SELECT * FROM interest_map) b ON a.interest_id::int = b.id
		ORDER BY b.id
	) c
)

-- number of id in interest_metrics but not in interest_map
SELECT COUNT(DISTINCT interest_id) - (SELECT nb FROM nb_common_id) as nb
FROM interest_metrics

-- number of id in interest_map but not in interest_metrics
SELECT COUNT(DISTINCT id) - (SELECT nb FROM nb_common_id) as nb
FROM interest_map

/* 5- Summarise the id values in the interest_map by its total record count in this table */

SELECT COUNT(DISTINCT id) nb
FROM interest_map

/* 6- What sort of table join should we perform for our analysis and why? 
	Check your logic by checking the rows where interest_id = 21246 in your 
	joined output and include all columns from interest_metrics and all 
	columns from interest_map except from the id column. */

SELECT *
FROM interest_map map
INNER JOIN interest_metrics metrics ON map.id = metrics.interest_id::int
WHERE metrics.interest_id::int = 21246 AND metrics._month IS NOT NULL; 

/* 7- Are there any records in your joined table where the month_year value 
	is before the created_at value from the interest_map table? 
	Do you think these values are valid and why? */

SELECT * 
FROM (
	SELECT *
	FROM interest_metrics a
	LEFT JOIN (SELECT * FROM interest_map) b ON a.interest_id::int = b.id
	ORDER BY b.id
) c
WHERE c.month_year < c.created_at
