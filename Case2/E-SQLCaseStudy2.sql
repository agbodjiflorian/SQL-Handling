/*
SELECT * FROM pizza_names LIMIT 3
SELECT * FROM pizza_recipes LIMIT 3
SELECT * FROM pizza_toppings LIMIT 3
*/

/*
If Danny wants to expand his range of pizzas - how would this impact 
the existing data design? Write an INSERT statement to demonstrate 
what would happen if a new Supreme pizza with all the toppings was 
added to the Pizza Runner menu?
*/

-- 1
INSERT INTO pizza_names
VALUES (3, 'Supreme')

SELECT * FROM pizza_names LIMIT 3

-- 2 
INSERT INTO pizza_recipes
VALUES (3, (SELECT string_agg(topping_id::varchar, ',') FROM pizza_toppings))

SELECT * FROM pizza_recipes LIMIT 3

-- 3
SELECT *
FROM pizza_names
INNER JOIN pizza_recipes USING(pizza_id)
