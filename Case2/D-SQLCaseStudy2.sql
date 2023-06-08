/*
SELECT * FROM runners LIMIT 3
SELECT * FROM customer_orders LIMIT 3
SELECT * FROM runner_orders LIMIT 3
SELECT * FROM pizza_names LIMIT 3
SELECT * FROM pizza_recipes LIMIT 3
SELECT * FROM pizza_toppings LIMIT 3
*/

/*
1-If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and 
	there were no charges for changes - how much money has Pizza Runner 
	made so far if there are no delivery fees?
*/

SELECT SUM(c.price) as profit
FROM (
	SELECT a.row, a.order_id, a.customer_id, a.pizza_id, b.pizza_name, 
		CASE
			WHEN b.pizza_name = 'Vegetarian' THEN 10
			ELSE 12
		END as price
	FROM (
		SELECT ROW_NUMBER() OVER(ORDER BY order_id) as row, order_id, customer_id, pizza_id
			FROM customer_orders
	) a
	JOIN pizza_names b
		ON a.pizza_id = b.pizza_id
	JOIN runner_orders z
		ON a.order_id = z.order_id
	WHERE z.cancellation IS NULL
	GROUP BY a.row, a.order_id, a.customer_id, a.pizza_id, b.pizza_name
) c


/*
2- What if there was an additional $1 charge for any pizza extras?
	Add cheese is $1 extra
*/

WITH cte as (
	SELECT a.row, a.order_id, a.customer_id, a.pizza_id, a.extras, a.order_time, COUNT(a.val) as price_extras
	FROM (
		SELECT t.row, t.order_id, t.customer_id, t.pizza_id, t.extras, t.order_time, TRIM(value) as val
		FROM (
			SELECT ROW_NUMBER() OVER(ORDER BY order_id) as row, order_id, customer_id, pizza_id, extras, order_time
			FROM customer_orders
		) t
		LEFT JOIN LATERAL unnest(string_to_array(t.extras, ',')) as value ON TRUE
	) a
	GROUP BY a.row, a.order_id, a.customer_id, a.pizza_id, a.extras, a.order_time
	ORDER BY a.row
)

SELECT sum(c.price_with_extras) as profit_with_extras
FROM (
	SELECT j.row, j.order_id, j.customer_id, j.pizza_id, j.pizza_name, j.extras, j.price_extras, j.price, j.price_with_extras
	FROM (
		SELECT m.row, m.order_id, m.customer_id, m.pizza_id, n.pizza_name, m.extras, m.price_extras,
			CASE
				WHEN n.pizza_name = 'Vegetarian' THEN 10
				ELSE 12
			END as price,
			CASE
				WHEN n.pizza_name = 'Vegetarian' THEN (10 + m.price_extras)
				ELSE (12 + m.price_extras)
			END as price_with_extras
	  	FROM cte m
		JOIN pizza_names n
			ON m.pizza_id = n.pizza_id
		GROUP BY m.row, m.order_id, m.customer_id, m.pizza_id, n.pizza_name, m.extras, m.price_extras
	) j
	JOIN runner_orders z
		ON j.order_id = z.order_id
	WHERE z.cancellation IS NULL
	GROUP BY j.row, j.order_id, j.customer_id, j.pizza_id, j.pizza_name, j.extras, j.price_extras, j.price, j.price_with_extras
	ORDER BY j.order_id
) c

/*
3- The Pizza Runner team now wants to add an additional ratings system 
	that allows customers to rate their runner, how would you design 
	an additional table for this new dataset - generate a schema for 
	this new table and insert your own data for ratings for each successful 
	customer order between 1 to 5.
*/

DROP TABLE IF EXISTS rating

CREATE TABLE rating 
(order_id INTEGER, rating INTEGER, commentss VARCHAR(100)) 

-- Order 6 and 9 were cancelled
INSERT INTO rating
VALUES ('1', '1', 'Really bad service'),
       ('2', '1', NULL),
       ('3', '4', 'Took too long...'),
       ('4', '1','Runner was lost, delivered it afterr an hourr. Pizza arrived cold' ),
       ('5', '2', 'Good service'),
       ('7', '5', 'It was great, good service and fast'),
       ('8', '2', 'He tossed it on the doorstep, poor service'),
       ('10', '5', 'Delicious!, he delivered it sooner than expected too!')

SELECT * FROM rating


/*
4- Using your newly generated table - can you join all of the information 
together to form a table which has the following information for successful deliveries?

	customer_id, order_id, runner_id, rating, order_time, pickup_time, 
	Time between order and pickup, Delivery duration, Average speed, Total number of pizzas
*/

 --convert the dataype of pickup_time in timestamp
ALTER TABLE runner_orders
	ALTER COLUMN pickup_time TYPE TIMESTAMP USING pickup_time::timestamp without time zone

SELECT t.order_id, t.customer_id, t.runner_id, t.ratings, t.order_time, 
	t.pickup_time, TRUNC(t.time_diff_in_min/60), t.duration, t.speed, r.nb_pizza
FROM (
	SELECT a.order_id, a.customer_id, b.runner_id, c.ratings, a.order_time, b.pickup_time, 
		EXTRACT(EPOCH FROM b.pickup_time - a.order_time) as time_diff_in_min, 
		b.duration, ROUND(CAST((b.distance*60/b.duration) AS numeric), 2) as speed
	FROM customer_orders a
	JOIN runner_orders b
		ON a.order_id = b.order_id
	JOIN rating c
		ON a.order_id = c.order_id
	WHERE b.cancellation IS NULL
	GROUP BY a.order_id, a.customer_id, b.runner_id, c.ratings, 
		a.order_time, b.pickup_time, b.duration, b.distance
) t
JOIN (
	SELECT order_id, count(*) as nb_pizza
	FROM customer_orders
	GROUP BY order_id
) r
	ON t.order_id = r.order_id
GROUP BY t.order_id, t.customer_id, t.runner_id, t.ratings, t.order_time, 
	t.pickup_time, t.time_diff_in_min, t.duration, t.speed, r.nb_pizza
ORDER BY t.order_time


/*
5- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with 
	no cost for extras and each runner is paid $0.30 per kilometre traveled 
	- how much money does Pizza Runner have left over after these deliveries?
*/

SELECT n.total_benef_pizza, d.total_km, (n.total_benef_pizza - d.total_km) as pizza_revenue
FROM (
	SELECT ROW_NUMBER() OVER() as nb_row, sum(m.fixed_price)as total_benef_pizza
	FROM (
		SELECT a.nb_row, a.order_id, a.customer_id, a.pizza_id, c.pizza_name, a.order_time,
			CASE
				WHEN c.pizza_name = 'Vegetarian' THEN 10
				ELSE 12
			END as fixed_price
		FROM (
			SELECT ROW_NUMBER() OVER(ORDER BY order_id) as nb_row, order_id, customer_id, pizza_id, order_time
			FROM customer_orders 
		) a
		JOIN runner_orders b
			ON a.order_id = b.order_id
		JOIN pizza_names c
			ON a.pizza_id = c.pizza_id
		WHERE b.cancellation IS NULL
		GROUP BY a.nb_row, a.order_id, a.customer_id, a.pizza_id, c.pizza_name, a.order_time
	) m
) n
JOIN (
	SELECT ROW_NUMBER() OVER() as n_row, SUM(p.paid_per_km) as total_km
	FROM (
		SELECT order_id, ROUND(CAST((0.30 * distance) AS numeric), 2) as paid_per_km
		FROM runner_orders
	) p
) d
	ON n.nb_row = d.n_row