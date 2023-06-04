/*
SELECT * FROM runners LIMIT 3
SELECT * FROM customer_orders LIMIT 3
SELECT * FROM runner_orders LIMIT 3
SELECT * FROM pizza_names LIMIT 3
SELECT * FROM pizza_recipes LIMIT 3
SELECT * FROM pizza_toppings LIMIT 3
*/

/* C. Ingredient Optimisation */


-- 1- What are the standard ingredients for each pizza?
	-- to change the datatype in the column
ALTER TABLE pizza_recipes
ALTER COLUMN toppings TYPE VARCHAR(50)

	-- result
	/* I consider the standard ingredients as the one that appears in both types of pizzas */
SELECT c.vall as standard_ingredients
FROM (
	SELECT b.vall, COUNT(b.vall) as nb_common_toppings
	FROM (
		SELECT TRIM(a.val) as vall
		FROM (
			SELECT pizza_id, f as val
			FROM pizza_recipes 
			LEFT JOIN LATERAL unnest(string_to_array(toppings, ',')) f ON true
		) a
	) b
	GROUP BY b.vall
) c
WHERE c.nb_common_toppings = (
	SELECT COUNT(DISTINCT pizza_id) as nb_piz
	FROM pizza_recipes
)

-- 2- What was the most commonly added extra?

SELECT a.val as extra, COUNT(a.val) as nb_times
FROM (
	SELECT order_id, extras, TRIM(f) as val
	FROM customer_orders
		LEFT JOIN LATERAL unnest(string_to_array(extras, ',')) f ON true
) a
GROUP BY a.val
ORDER BY COUNT(a.val) DESC
LIMIT 1

-- 3- What was the most common exclusion?

SELECT a.val as exclusions, COUNT(a.val) as nb_times
FROM (
	SELECT order_id, exclusions, TRIM(f) as val
	FROM customer_orders
		LEFT JOIN LATERAL unnest(string_to_array(exclusions, ',')) f ON true
) a
GROUP BY a.val
ORDER BY COUNT(a.val) DESC
LIMIT 1

/*
4- Generate an order item for each record in the customers_orders 
	table in the format of one of the following:
		°Meat Lovers
		°Meat Lovers - Exclude Beef
		°Meat Lovers - Extra Bacon
		°Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/
-- let's try to write the name of the toppings in each pizza
SELECT c.pizza_id, string_agg(DISTINCT c.topping_name, ',') as ingredients
FROM (
	SELECT a.pizza_id, a.each_topping_id, b.topping_name
	FROM (
		SELECT pizza_id, TRIM(value) as each_topping_id
		FROM pizza_recipes
			LEFT JOIN LATERAL unnest(string_to_array(toppings, ',')) as value ON TRUE
	) a
	INNER JOIN pizza_toppings as b
		ON a.each_topping_id::int = b.topping_id
) c
GROUP BY c.pizza_id

	--Result
WITH cte as (
	SELECT k.rows, k.customer_id, k.pizza_name, k.exclu_name, k.extra_name
	FROM (
		SELECT d.rows, d.order_id, d.customer_id, d.pizza_id, d.pizza_name, e.topping_name as exclu_name, f.topping_name as extra_name
		FROM (
			SELECT c.rows, c.order_id, c.customer_id, c.pizza_id, c.pizza_name, TRIM(excl) as exclu, TRIM(extr) as extra
			FROM (
				SELECT a.order_id, a.customer_id, a.pizza_id, a.exclusions, a.extras, b.pizza_name, 
					ROW_NUMBER() OVER(ORDER BY a.order_id) as rows
				FROM customer_orders a
				JOIN pizza_names b
					ON a.pizza_id = b.pizza_id
				ORDER BY a.order_id, a.customer_id, a.pizza_id
			) c
			LEFT JOIN LATERAL unnest(string_to_array(exclusions, ',')) as excl ON true
			LEFT JOIN LATERAL unnest(string_to_array(extras, ',')) as extr ON true
			ORDER BY c.order_id, c.customer_id, c.pizza_id
		) d
		LEFT JOIN pizza_toppings e
			ON d.exclu::int = e.topping_id
		LEFT JOIN pizza_toppings f
			ON d.extra::int = f.topping_id
		ORDER BY d.order_id, d.customer_id, d.pizza_id
	) k
	ORDER BY k.rows
)

SELECT j.customer_id,
	CASE
		WHEN all_exclu IS NULL AND all_extra IS NULL THEN j.pizza_name
		WHEN all_exclu IS NULL AND all_extra IS NOT NULL THEN concat(j.pizza_name, ' - Extra ', j.all_extra)
		WHEN all_exclu IS NOT NULL AND all_extra IS NULL THEN concat(j.pizza_name, ' - Exclude ', j.all_exclu)
		ELSE concat(j.pizza_name, ' - Exclude ', j.all_exclu, ' - Extra ', j.all_extra)
	END as order_made
FROM (
	SELECT l.rows, l.customer_id, l.pizza_name, string_agg(DISTINCT l.exclu_name, ',') as all_exclu, string_agg(DISTINCT l.extra_name, ',') as all_extra
	FROM cte l
	GROUP BY l.rows, l.customer_id, l.pizza_name
) j

/* 
5- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
	For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
	
	1- Use the Extras column
	2- Concat the Extras column with the pizza ingredients column 
	3- Convert the concatenated strings in array using LEFT JOIN LATERAL
	4- Count the recurrence of each word in the string
	5- Convert the words to strings using their recurrences and the alphabetic order
*/

WITH cte as (
	SELECT k.rows, k.customer_id, k.pizza_id, k.pizza_name, k.exclu_name, k.extra_name
	FROM (
		SELECT d.rows, d.order_id, d.customer_id, d.pizza_id, d.pizza_name, e.topping_name as exclu_name, f.topping_name as extra_name
		FROM (
			SELECT c.rows, c.order_id, c.customer_id, c.pizza_id, c.pizza_name, TRIM(excl) as exclu, TRIM(extr) as extra
			FROM (
				SELECT a.order_id, a.customer_id, a.pizza_id, a.exclusions, a.extras, b.pizza_name, 
					ROW_NUMBER() OVER(ORDER BY a.order_id) as rows
				FROM customer_orders a
				JOIN pizza_names b
					ON a.pizza_id = b.pizza_id
				ORDER BY a.order_id, a.customer_id, a.pizza_id
			) c
			LEFT JOIN LATERAL unnest(string_to_array(exclusions, ',')) as excl ON true
			LEFT JOIN LATERAL unnest(string_to_array(extras, ',')) as extr ON true
			ORDER BY c.order_id, c.customer_id, c.pizza_id
		) d
		LEFT JOIN pizza_toppings e
			ON d.exclu::int = e.topping_id
		LEFT JOIN pizza_toppings f
			ON d.extra::int = f.topping_id
		ORDER BY d.order_id, d.customer_id, d.pizza_id
	) k
	ORDER BY k.rows
)

SELECT q.rows, q.customer_id, q.pizza_name, string_agg(q.occu, ', ' ORDER BY q.occu)
FROM (
	SELECT v.rows, v.customer_id, v.pizza_name, 
		CASE
			WHEN v.rec = 1 THEN v.val
			ELSE CONCAT(v.rec, 'x', v.val) 
		END as occu
	FROM (
		SELECT x.rows, x.customer_id, x.pizza_name, x.val, COUNT(x.val) as rec
		FROM (
			SELECT t.rows, t.customer_id, t.pizza_name, val
			FROM (
				SELECT m.rows, m.customer_id, m.pizza_name, 
					CASE
						WHEN m.extra_name IS NULL THEN p.ingredients
						ELSE CONCAT(m.extra_name, ',', p.ingredients)
					END as ingredient
				FROM cte m
				JOIN (
				-- let's try to write the name of the toppings in each pizza
					SELECT c.pizza_id, string_agg(DISTINCT c.topping_name, ',') as ingredients
					FROM (
						SELECT a.pizza_id, a.each_topping_id, b.topping_name
						FROM (
							SELECT pizza_id, TRIM(value) as each_topping_id
							FROM pizza_recipes
								LEFT JOIN LATERAL unnest(string_to_array(toppings, ',')) as value ON TRUE
						) a
						INNER JOIN pizza_toppings as b
							ON a.each_topping_id::int = b.topping_id
					) c
					GROUP BY c.pizza_id
				) p
					ON m.pizza_id = p.pizza_id
				GROUP BY  m.rows, m.customer_id, m.pizza_name, m.extra_name, p.ingredients
			) t
			LEFT JOIN LATERAL unnest(string_to_array(ingredient, ',')) as val ON true
		) x
		GROUP BY x.rows, x.customer_id, x.pizza_name, x.val
	) v
	GROUP BY v.rows, v.customer_id, v.pizza_name, v.rec, v.val
) q
GROUP BY q.rows, q.customer_id, q.pizza_name

/*
6- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first? 
	Using the CTE in 5/ the answer is:
*/
	SELECT x.val, COUNT(x.val) as rec
		FROM (
			SELECT t.rows, t.customer_id, t.pizza_name, val
			FROM (
				SELECT m.rows, m.customer_id, m.pizza_name, 
					CASE
						WHEN m.extra_name IS NULL THEN p.ingredients
						ELSE CONCAT(m.extra_name, ',', p.ingredients)
					END as ingredient
				FROM cte m
				JOIN (
				-- let's try to write the name of the toppings in each pizza
					SELECT c.pizza_id, string_agg(DISTINCT c.topping_name, ',') as ingredients
					FROM (
						SELECT a.pizza_id, a.each_topping_id, b.topping_name
						FROM (
							SELECT pizza_id, TRIM(value) as each_topping_id
							FROM pizza_recipes
								LEFT JOIN LATERAL unnest(string_to_array(toppings, ',')) as value ON TRUE
						) a
						INNER JOIN pizza_toppings as b
							ON a.each_topping_id::int = b.topping_id
					) c
					GROUP BY c.pizza_id
				) p
					ON m.pizza_id = p.pizza_id
				GROUP BY  m.rows, m.customer_id, m.pizza_name, m.extra_name, p.ingredients
			) t
			LEFT JOIN LATERAL unnest(string_to_array(ingredient, ',')) as val ON true
		) x
		GROUP BY x.val
		ORDER BY COUNT(x.val) DESC
		