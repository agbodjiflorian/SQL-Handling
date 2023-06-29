/*
SELECT * FROM regions LIMIT 5
SELECT * FROM customer_nodes LIMIT 5
SELECT * FROM customer_transactions LIMIT 5
*/

/* A. Customer Nodes Exploration */

-- 1- How many unique nodes are there on the Data Bank system?

SELECT COUNT(DISTINCT node_id) as nb_nodes
FROM customer_nodes

-- 2- What is the number of nodes per region?

SELECT a.region_id, a.region_name, COUNT(b.node_id) as nb_nodes_per_region
FROM regions a 
JOIN customer_nodes b
	ON a.region_id = b.region_id
GROUP BY a.region_id, a.region_name

-- 3- How many customers are allocated to each region?

SELECT a.region_id, a.region_name, COUNT(DISTINCT customer_id) as nb_customer_per_region
FROM regions a 
JOIN customer_nodes b
	ON a.region_id = b.region_id
GROUP BY a.region_id, a.region_name

-- 4- How many days on average are customers reallocated to a different node?

SELECT ROUND(AVG(a.nb_days_with_a_node), 2) nb_days_to_get_reallocated
FROM (
	SELECT customer_id, start_date, end_date, (end_date - start_date) as nb_days_with_a_node
	FROM customer_nodes
	GROUP BY customer_id, start_date, end_date
) a
-- OR
SELECT ROUND(AVG(a.nb_days_with_a_node), 2) nb_days_to_get_reallocated
FROM (
	SELECT customer_id, start_date, end_date, (end_date - start_date) as nb_days_with_a_node
	FROM customer_nodes
	WHERE end_date != '9999-12-31'
	GROUP BY customer_id, start_date, end_date
) a

/* 5- What is the median, 80th and 95th percentile for this 
	same reallocation days metric for each region? */

WITH cte as (
	SELECT region_id, customer_id, start_date, end_date, (end_date - start_date) as nb_days_with_a_node
	FROM customer_nodes
	WHERE end_date != '9999-12-31'
	GROUP BY region_id, customer_id, start_date, end_date
	ORDER BY region_id
)

SELECT region_id, 
	PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY nb_days_with_a_node) as median,
	PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY nb_days_with_a_node) as percentile_80,
	PERCENTILE_CONT(0.95) WITHIN GROUP(ORDER BY nb_days_with_a_node) as percentile_95
FROM cte
GROUP BY region_id
