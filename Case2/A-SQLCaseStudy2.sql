
SELECT * FROM runners LIMIT 3
SELECT * FROM customer_orders LIMIT 3
SELECT * FROM runner_orders LIMIT 3
SELECT * FROM pizza_names LIMIT 3
SELECT * FROM pizza_recipes LIMIT 3
SELECT * FROM pizza_toppings LIMIT 3

/* A. Pizza Metrics */

-- 1- How many pizzas were ordered?
--	 clean the table first

UPDATE customer_orders
SET exclusions = NULL
WHERE exclusions = 'null'

UPDATE customer_orders
SET extras = NULL
WHERE extras = 'null'

SELECT COUNT(pizza_id) as nb_pizza
FROM customer_orders

--	2- How many unique customer orders were made?

SELECT COUNT(DISTINCT customer_id) as nb
FROM customer_orders

--	3- How many successful orders were delivered by each runner?

--		 Update the table to correct the mistakes in each column
UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation IN ('', 'null') 

UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null'
		
UPDATE runner_orders
SET distance = NULL
WHERE distance = 'null'

UPDATE runner_orders
SET duration = NULL
WHERE duration = 'null'

UPDATE runner_orders
SET distance = RTRIM(REPLACE(distance, 'km', ''))
WHERE distance IS NOT NULL

UPDATE runner_orders
SET duration = Substring(duration, 1,2)
WHERE duration IS NOT NULL

--Result:
SELECT a.runner_id, b.nb as nb_succesful_order
FROM runners a
JOIN (
	SELECT runner_id, COUNT(runner_id) as nb
	FROM runner_orders
	WHERE cancellation IS NULL 
	GROUP BY runner_id 
) b
	ON a.runner_id = b.runner_id
GROUP BY a.runner_id, b.nb

--	4- How many of each type of pizza was delivered?

ALTER TABLE pizza_names
ALTER COLUMN pizza_name TYPE varchar(30)

SELECT d.pizza_name, COUNT(d.pizza_name) as nb_pizza
FROM (
	SELECT a.pizza_id, a.pizza_name, b.order_id, c.cancellation
	FROM pizza_names a
	JOIN customer_orders b
		ON a.pizza_id = b.pizza_id
	JOIN runner_orders c
		ON b.order_id = c.order_id
) d
WHERE d.cancellation IS NULL
GROUP BY d.pizza_name

--	5- How many Vegetarian and Meatlovers were ordered by each customer?

SELECT a.customer_id, b.pizza_name, COUNT(b.pizza_name) as nb
FROM customer_orders a
JOIN pizza_names b
	ON a.pizza_id = b.pizza_id
GROUP BY a.customer_id, b.pizza_name
ORDER BY a.customer_id

--	6- What was the maximum number of pizzas delivered in a single order?

SELECT MAX(c.nb) as nb_max
FROM (
	SELECT a.order_id, COUNT(a.order_id) as nb
	FROM customer_orders a
	JOIN runner_orders b
		ON a.order_id = b.order_id
	WHERE b.cancellation IS NULL
	GROUP BY a.order_id
) c

--	7- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
 
 --		 before it's important to update and clean the exclusions and extras columns
 UPDATE customer_orders
 SET exclusions = NULL
 WHERE exclusions = ''

 UPDATE customer_orders
 SET extras = NULL
 WHERE extras = ''

 -- Result

SELECT e.customer_id, e.nb_delivered, d.no_changes, (e.nb_delivered - d.no_changes) as with_changes
FROM (
	SELECT c.customer_id, c.change, COUNT(c.change) as no_changes
	FROM (
		SELECT a.customer_id, a.exclusions, a.extras,
				CASE
					WHEN a.exclusions IS NULL AND a.extras IS NULL THEN 'no changes'
					ELSE 'changes'
				END as change
		FROM customer_orders a
		JOIN runner_orders b
			ON a.order_id = b.order_id
		WHERE b.cancellation IS NULL
	) c
	WHERE c.change = 'no changes'
	GROUP BY c.customer_id, c.change
) d
RIGHT JOIN (
	SELECT a.customer_id, COUNT(a.customer_id) as nb_delivered
	FROM customer_orders a
	JOIN runner_orders b
		ON a.order_id = b.order_id
	WHERE b.cancellation IS NULL
	GROUP BY a.customer_id
) e
	ON d.customer_id = e.customer_id

--	8- How many pizzas were delivered that had both exclusions and extras?

SELECT COUNT(c.pizza_id) 
FROM (
	SELECT a.pizza_id, a.exclusions, a.extras,
			CASE
				WHEN a.exclusions IS NOT NULL AND a.extras IS NOT NULL THEN 'both'
				ELSE 'no'
			END as change
	FROM customer_orders a
	JOIN runner_orders b
		ON a.order_id = b.order_id
	WHERE b.cancellation IS NULL
) c
WHERE c.change = 'both'

--	9- What was the total volume of pizzas ordered for each hour of the day?

SELECT a.dayy, a.hourr, COUNT(a.hourr) as nb
FROM (
	SELECT order_time, order_time::date as dayy, order_time::time as temps, EXTRACT(hour from order_time) as hourr 
	FROM customer_orders
) a
GROUP BY a.dayy, a.hourr
ORDER BY a.dayy, a.hourr

--	10- What was the volume of orders for each day of the week?

SELECT  CASE 
			 WHEN a.day_week=0 THEN 'Sunday'
			 WHEN a.day_week=1 THEN 'Monday'
			 WHEN a.day_week=2 THEN 'Tuesday'
			 WHEN a.day_week=3 THEN 'Wednesday'
			 WHEN a.day_week=4 THEN 'Thursday'
			 WHEN a.day_week=5 THEN 'Friday'
			 WHEN a.day_week=6 THEN 'Saturday'
		 	 ELSE 'other day'
		END as day_week,  
		COUNT(a.day_week) as nb
FROM (
	SELECT order_time::date as dayy, EXTRACT(dow from order_time) as day_week
	FROM customer_orders
) a
GROUP BY a.day_week
ORDER BY a.day_week


