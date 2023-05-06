
SELECT TOP 5 * FROM sales
SELECT TOP 5 * FROM menu
SELECT TOP 5 * FROM members

-- 1- What is the total amount each customer spent at the restaurant?

SELECT c.customer_id, SUM(c.price) as total_amount
FROM (
	SELECT a.customer_id, a.product_id, b.price
	FROM sales a
	JOIN menu b
		ON a.product_id = b.product_id
) c
GROUP BY c.customer_id

-- 2- How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) as nb_days
FROM sales
GROUP BY customer_id

-- 3- What was the first item from the menu purchased by each customer?

SELECT c.customer_id, c.product_name
FROM (
	SELECT a.customer_id, a.order_date, a.product_id, b.product_name, 
		ROW_NUMBER() OVER(PARTITION BY a.customer_id ORDER BY a.order_date) as row
	FROM sales a
	JOIN menu b
		ON a.product_id = b.product_id 
	GROUP BY a.customer_id, a.order_date, a.product_id, b.product_name
) c
WHERE c.row = 1

-- 4- What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 c.product_name, COUNT(c.product_name) as nb_time
FROM (
	SELECT a.customer_id, b.product_name
	FROM sales a
	JOIN menu b
		ON a.product_id = b.product_id
) c
GROUP BY c.product_name
ORDER BY COUNT(c.product_name) DESC

-- 5- Which item was the most popular for each customer?

SELECT c.customer_id, c.product_name
FROM (
	SELECT a.customer_id, b.product_name, COUNT(b.product_name) as nb_time, 
		ROW_NUMBER() OVER(PARTITION BY a.customer_id ORDER BY COUNT(b.product_name) DESC) as row
	FROM sales a
	JOIN menu b
		ON a.product_id = b.product_id
	GROUP BY a.customer_id, b.product_name
) c
WHERE c.row = 1

-- 6- Which item was purchased first by the customer after they became a member?

SELECT d.customer_id, d.product_name
FROM (
	SELECT a.customer_id, a.order_date, a.product_id, b.product_name, c.join_date,
		ROW_NUMBER() OVER(PARTITION BY a.customer_id ORDER BY a.order_date) as row
	FROM sales a
	JOIN menu b
		ON a.product_id = b.product_id
	JOIN members c
		ON a.customer_id = c.customer_id
	WHERE a.order_date > c.join_date
) d
WHERE d.row = 1

-- 7- Which item was purchased just before the customer became a member?

SELECT d.customer_id, d.product_name
FROM (
	SELECT a.customer_id, a.order_date, a.product_id, b.product_name, c.join_date,
		ROW_NUMBER() OVER(PARTITION BY a.customer_id ORDER BY a.order_date DESC) as row
	FROM sales a
	JOIN menu b
		ON a.product_id = b.product_id 
	JOIN members c
		ON a.customer_id = c.customer_id
	WHERE a.order_date < c.join_date
) d
WHERE d.row = 1

-- 8- What is the total items and amount spent for each member before they became a member?

SELECT d.customer_id, COUNT(d.customer_id) as nb_item, SUM(d.price) as amount_spent
FROM (
	SELECT a.customer_id, a.order_date, a.product_id, b.product_name, b.price, c.join_date
	FROM sales a
	JOIN menu b
		ON a.product_id = b.product_id 
	JOIN members c
		ON a.customer_id = c.customer_id
	WHERE a.order_date < c.join_date
) d
GROUP BY d.customer_id

-- 9- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT c.customer_id, SUM(points)
FROM (
	SELECT a.customer_id, a.order_date, a.product_id, b.product_name, b.price, 
		CASE
			WHEN b.product_name = 'sushi' THEN (b.price * 10 * 2)
			ELSE (b.price * 10)

		END as points
	FROM sales a
	JOIN menu b
		ON a.product_id = b.product_id 
) c
GROUP BY c.customer_id

/*
10- In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi 
	- how many points do customer A and B have at the end of January?

	R :
	- select all the items ordered before the end of january
	- then check the items ordered during the first week after they join and add 2x points
	- check sushi and add 2x points
	- 1x for the others
*/

SELECT d.customer_id, SUM(d.points) as nb_points
FROM (
	SELECT a.customer_id, a.order_date, b.product_name, b.price, c.join_date, 
		DATEADD(week, 1, c.join_date) as first_week,
		CASE
			WHEN c.join_date <= a.order_date AND a.order_date < DATEADD(week, 1, c.join_date) THEN (b.price * 10 * 2)
			WHEN b.product_name = 'sushi' THEN (b.price * 10 * 2)
			ELSE (b.price * 10 * 1)
		END as points
	FROM sales a
	JOIN menu b
		ON a.product_id = b.product_id 
	JOIN members c
		ON a.customer_id = c.customer_id
	WHERE a.order_date < EOMONTH(c.join_date)
) d
GROUP BY d.customer_id

