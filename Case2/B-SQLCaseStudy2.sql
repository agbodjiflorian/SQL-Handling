SELECT * FROM runners LIMIT 3
SELECT * FROM customer_orders LIMIT 3
SELECT * FROM runner_orders LIMIT 3
SELECT * FROM pizza_names LIMIT 3
SELECT * FROM pizza_recipes LIMIT 3
SELECT * FROM pizza_toppings LIMIT 3


/* B. Runner and Customer Experience */

-- 1- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

	-- try to identify all the weeks first
/*
DECLARE @f DATE, @l DATE
SELECT @f = a.first_date, @l = a.last_date
FROM (
	SELECT MIN(registration_date) as first_date, MAX(registration_date) as last_date
	FROM runners
) a
	
WHILE (@l < DATEADD(week, 1, @f))
BEGIN
	PRINT (CONCAT(@f, '-', DATEADD(week, 1, @f))) 
	SET @f = DATEADD(week, 1, @f)
END 
*/

-- 2- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT * FROM runner_orders
ALTER TABLE runner_orders
ALTER COLUMN pickup_time TYPE TIMESTAMP

SELECT d.runner_id, AVG(a.min_diff) avg_time
FROM runners d
LEFT JOIN (
	SELECT b.runner_id, c.order_time, b.pickup_time, 
		DATE_PART('minute', b.pickup_time::timestamp - c.order_time::timestamp) as min_diff
	FROM runner_orders b
	JOIN customer_orders c
		ON b.order_id = c.order_id
) a
	ON d.runner_id = a.runner_id
GROUP BY d.runner_id

-- 3- Is there any relationship between the number of pizzas and how long the order takes to prepare?

	-- a- let's try to verify how long it takes to pickup depending on both the number of pizzas ordered and the order_id

SELECT a.order_id, COUNT(a.order_id) nb_pizza_ordered, DATE_PART('minute', b.pickup_time::timestamp - a.order_time::timestamp) as how_long
FROM customer_orders a
JOIN runner_orders b
	ON a.order_id = b.order_id
WHERE b.cancellation IS NULL
GROUP BY a.order_id, a.order_time, b.pickup_time

	-- b- let's verify the average of time it takes to pickup for each number of pizzas ordered

SELECT c.nb_pizza_ordered, AVG(c.how_long) average_time
FROM (
	SELECT a.order_id, COUNT(a.order_id) nb_pizza_ordered, DATE_PART('minute', b.pickup_time::timestamp - a.order_time::timestamp) as how_long
	FROM customer_orders a
	JOIN runner_orders b
		ON a.order_id = b.order_id
	WHERE b.cancellation IS NULL
	GROUP BY a.order_id, a.order_time, b.pickup_time
) c
GROUP BY c.nb_pizza_ordered

-- 4- What was the average distance travelled for each customer?
	-- convert the column distance in float
	ALTER TABLE runner_orders
	ALTER COLUMN distance TYPE real USING distance::real

SELECT c.order_id, ROUND(CAST(c.avg_distance AS numeric), 2) as avg_dist
FROM (
	SELECT a.order_id, AVG(b.distance) as avg_distance
	FROM customer_orders a
	JOIN runner_orders b
		ON a.order_id = b.order_id
	WHERE b.cancellation IS NULL
	GROUP BY a.order_id
) c
GROUP BY c.order_id, c.avg_distance

-- 5- What was the difference between the longest and shortest delivery times for all orders?
	-- convert the column duration in float
	ALTER TABLE runner_orders
	ALTER COLUMN duration TYPE real USING duration::real

SELECT (MAX(duration) - MIN(duration)) as diff
FROM runner_orders

-- 6- What was the average speed for each runner for each delivery and do you notice any trend for these values?


SELECT a.runner_id, b.avg_speed
FROM runners a
JOIN (
	SELECT c.runner_id, c.distance, c.duration, ROUND(CAST(AVG(c.speed_km_minute) AS numeric), 2) as avg_speed
	FROM (
		SELECT runner_id, distance, duration, distance/duration as speed_km_minute
		FROM runner_orders
		WHERE cancellation IS NULL
		GROUP BY runner_id, distance, duration
	) c
	GROUP BY c.runner_id, c.distance, c.duration, c.speed_km_minute
) b
	ON a.runner_id = b.runner_id
GROUP BY a.runner_id, b.avg_speed


-- 7- What is the successful delivery percentage for each runner?


SELECT c.runner_id, FLOOR(ROUND(CAST(100*c.sucessful/c.nb_runner AS numeric), 2)) as successful_percentage
FROM (
	SELECT a.runner_id, COUNT(a.runner_id) as sucessful, b.nb_runner
	FROM runner_orders a
	JOIN (
		SELECT runner_id, COUNT(runner_id) as nb_runner
		FROM runner_orders
		GROUP BY runner_id
	) b
		ON a.runner_id = b.runner_id
	WHERE a.cancellation IS NULL
	GROUP BY a.runner_id, b.nb_runner
) c
GROUP BY c.runner_id, c.sucessful, c.nb_runner