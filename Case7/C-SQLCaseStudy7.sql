/*
SELECT * FROM product_details LIMIT 5
SELECT * FROM sales LIMIT 5
SELECT * FROM product_hierarchy LIMIT 5
SELECT * FROM product_prices LIMIT 5
*/

/* C. Product Analysis */

-- 1- What are the top 3 products by total revenue before discount?

SELECT DISTINCT a.prod_id, b.product_name, SUM(a.revenue_normal) as total_revenue
FROM (
	SELECT prod_id, qty, price, qty * price as revenue_normal, ROUND(discount::numeric/100, 2) as discount_percent, member
	FROM sales
) a
JOIN (
	SELECT * FROM product_details 
) b
	ON a.prod_id = b.product_id
GROUP BY a.prod_id, b.product_name
ORDER BY SUM(a.revenue_normal) DESC

-- 2- What is the total quantity, revenue and discount for each segment?

SELECT d.segment_name, SUM(d.qty) as total_qty, SUM(d.revenue_normal) as normal_revenue,
	SUM(d.revenue_after_discount) as revenue_after_discount, SUM(d.discount_price) as discount_amount
FROM (
	SELECT b.prod_id, b.qty, b.price, b.revenue_normal, b.discount_percent, b.discount_price,
		b.revenue_normal - b.discount_price as revenue_after_discount, c.segment_name
	FROM (
		SELECT a.prod_id, a.qty, a.price, a.revenue_normal, a.discount_percent, 
			a.revenue_normal * a.discount_percent as discount_price, a.member
		FROM (
			SELECT prod_id, qty, price, qty * price as revenue_normal, 
				ROUND(discount::numeric/100, 2) as discount_percent, member
			FROM sales
		) a
	) b
	JOIN (SELECT * FROM product_details) c ON b.prod_id = c.product_id
) d
GROUP BY d.segment_name

-- 3- What is the top selling product for each segment?

SELECT *
FROM (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY e.segment_name ORDER BY e.total_qty DESC) as nb_row
	FROM (
		SELECT d.segment_name, d.prod_id, SUM(d.qty) as total_qty, SUM(d.revenue_normal) as normal_revenue,
			SUM(d.revenue_after_discount) as revenue_after_discount, SUM(d.discount_price) as discount_amount
		FROM (
			SELECT b.prod_id, b.qty, b.price, b.revenue_normal, b.discount_percent, b.discount_price,
				b.revenue_normal - b.discount_price as revenue_after_discount, c.segment_name
			FROM (
				SELECT a.prod_id, a.qty, a.price, a.revenue_normal, a.discount_percent, 
					a.revenue_normal * a.discount_percent as discount_price, a.member
				FROM (
					SELECT prod_id, qty, price, qty * price as revenue_normal, 
						ROUND(discount::numeric/100, 2) as discount_percent, member
					FROM sales
				) a
			) b
			JOIN (SELECT * FROM product_details) c ON b.prod_id = c.product_id
		) d
		GROUP BY d.segment_name, d.prod_id
	) e
) f
WHERE f.nb_row = 1
ORDER BY f.total_qty DESC

-- 4- What is the total quantity, revenue and discount for each category?

SELECT d.category_name, SUM(d.qty) as total_qty, SUM(d.revenue_normal) as normal_revenue,
	SUM(d.revenue_after_discount) as revenue_after_discount, SUM(d.discount_price) as discount_amount
FROM (
	SELECT b.prod_id, b.qty, b.price, b.revenue_normal, b.discount_percent, b.discount_price,
		b.revenue_normal - b.discount_price as revenue_after_discount, c.category_name
	FROM (
		SELECT a.prod_id, a.qty, a.price, a.revenue_normal, a.discount_percent, 
			a.revenue_normal * a.discount_percent as discount_price, a.member
		FROM (
			SELECT prod_id, qty, price, qty * price as revenue_normal, 
				ROUND(discount::numeric/100, 2) as discount_percent, member
			FROM sales
		) a
	) b
	JOIN (SELECT * FROM product_details) c ON b.prod_id = c.product_id
) d
GROUP BY d.category_name

-- 5- What is the top selling product for each category?

SELECT *
FROM (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY e.category_name ORDER BY e.total_qty DESC) as nb_row
	FROM (
		SELECT d.category_name, d.prod_id, SUM(d.qty) as total_qty, SUM(d.revenue_normal) as normal_revenue,
			SUM(d.revenue_after_discount) as revenue_after_discount, SUM(d.discount_price) as discount_amount
		FROM (
			SELECT b.prod_id, b.qty, b.price, b.revenue_normal, b.discount_percent, b.discount_price,
				b.revenue_normal - b.discount_price as revenue_after_discount, c.category_name
			FROM (
				SELECT a.prod_id, a.qty, a.price, a.revenue_normal, a.discount_percent, 
					a.revenue_normal * a.discount_percent as discount_price, a.member
				FROM (
					SELECT prod_id, qty, price, qty * price as revenue_normal, 
						ROUND(discount::numeric/100, 2) as discount_percent, member
					FROM sales
				) a
			) b
			JOIN (SELECT * FROM product_details) c ON b.prod_id = c.product_id
		) d
		GROUP BY d.category_name, d.prod_id
	) e
) f
WHERE f.nb_row = 1
ORDER BY f.total_qty DESC

-- 6- What is the percentage split of revenue by product for each segment?

WITH cte as (
	SELECT d.segment_name, d.prod_id, SUM(d.qty) as total_qty, SUM(d.revenue_normal) as normal_revenue,
		SUM(d.revenue_after_discount) as revenue_after_discount, SUM(d.discount_price) as discount_amount
	FROM (
		SELECT b.prod_id, b.qty, b.price, b.revenue_normal, b.discount_percent, b.discount_price,
			b.revenue_normal - b.discount_price as revenue_after_discount, c.segment_name
		FROM (
			SELECT a.prod_id, a.qty, a.price, a.revenue_normal, a.discount_percent, 
				a.revenue_normal * a.discount_percent as discount_price, a.member
			FROM (
				SELECT prod_id, qty, price, qty * price as revenue_normal, 
					ROUND(discount::numeric/100, 2) as discount_percent, member
				FROM sales
			) a
		) b
		JOIN (SELECT * FROM product_details) c ON b.prod_id = c.product_id
	) d
	GROUP BY d.segment_name, d.prod_id
) 

SELECT segment_name, prod_id,
	ROUND(100 * normal_revenue::numeric / (SELECT SUM(normal_revenue) FROM cte), 2) as percent_normal_revenue,
	ROUND(100 * revenue_after_discount::numeric / (SELECT SUM(revenue_after_discount) FROM cte), 2) as percent_revenue_after_discount
FROM cte
ORDER BY segment_name

-- 7- What is the percentage split of revenue by segment for each category?

WITH cte as (
	SELECT d.category_name, d.segment_name, SUM(d.qty) as total_qty, SUM(d.revenue_normal) as normal_revenue,
		SUM(d.revenue_after_discount) as revenue_after_discount, SUM(d.discount_price) as discount_amount
	FROM (
		SELECT b.prod_id, b.qty, b.price, b.revenue_normal, b.discount_percent, b.discount_price,
			b.revenue_normal - b.discount_price as revenue_after_discount, c.segment_name, c.category_name
		FROM (
			SELECT a.prod_id, a.qty, a.price, a.revenue_normal, a.discount_percent, 
				a.revenue_normal * a.discount_percent as discount_price, a.member
			FROM (
				SELECT prod_id, qty, price, qty * price as revenue_normal, 
					ROUND(discount::numeric/100, 2) as discount_percent, member
				FROM sales
			) a
		) b
		JOIN (SELECT * FROM product_details) c ON b.prod_id = c.product_id
	) d
	GROUP BY d.category_name, d.segment_name
) 

SELECT category_name, segment_name, 
	ROUND(100 * normal_revenue::numeric / (SELECT SUM(normal_revenue) FROM cte), 2) as percent_normal_revenue,
	ROUND(100 * revenue_after_discount::numeric / (SELECT SUM(revenue_after_discount) FROM cte), 2) as percent_revenue_after_discount
FROM cte
ORDER BY segment_name

-- 8- What is the percentage split of total revenue by category?

WITH cte as (
	SELECT d.category_name, SUM(d.qty) as total_qty, SUM(d.revenue_normal) as normal_revenue,
		SUM(d.revenue_after_discount) as revenue_after_discount, SUM(d.discount_price) as discount_amount
	FROM (
		SELECT b.prod_id, b.qty, b.price, b.revenue_normal, b.discount_percent, b.discount_price,
			b.revenue_normal - b.discount_price as revenue_after_discount, c.segment_name, c.category_name
		FROM (
			SELECT a.prod_id, a.qty, a.price, a.revenue_normal, a.discount_percent, 
				a.revenue_normal * a.discount_percent as discount_price, a.member
			FROM (
				SELECT prod_id, qty, price, qty * price as revenue_normal, 
					ROUND(discount::numeric/100, 2) as discount_percent, member
				FROM sales
			) a
		) b
		JOIN (SELECT * FROM product_details) c ON b.prod_id = c.product_id
	) d
	GROUP BY d.category_name
) 

SELECT category_name,
	ROUND(100 * normal_revenue::numeric / (SELECT SUM(normal_revenue) FROM cte), 2) as percent_normal_revenue,
	ROUND(100 * revenue_after_discount::numeric / (SELECT SUM(revenue_after_discount) FROM cte), 2) as percent_revenue_after_discount
FROM cte

/*9- What is the total transaction “penetration” for each product? 
	(hint: penetration = number of transactions where at least 1 quantity 
	of a product was purchased divided by total number of transactions) */

SELECT prod_id, ROUND(100*(COUNT(DISTINCT txn_id))::numeric/(SELECT COUNT(DISTINCT txn_id) FROM sales), 2) as penetration
FROM sales
WHERE qty >= 1
GROUP BY prod_id

/* 10- What is the most common combination of at least 1 quantity of 
		any 3 products in a 1 single transaction? */

WITH cte as (
	SELECT a.txn_id, a.prod_id, b.product_name
	FROM sales a
	JOIN (SELECT * FROM product_details) b ON a.prod_id = b.product_id
)

SELECT a.product_name, b.product_name, c.product_name, COUNT(*) as combination
FROM cte a
JOIN cte b ON a.txn_id = b.txn_id
JOIN cte c ON b.txn_id = c.txn_id
WHERE a.product_name < b.product_name AND b.product_name < c.product_name
GROUP BY a.product_name, b.product_name, c.product_name
ORDER BY COUNT(*) DESC 