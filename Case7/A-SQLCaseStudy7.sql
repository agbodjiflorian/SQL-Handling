/*
SELECT * FROM product_details LIMIT 5
SELECT * FROM sales LIMIT 5
SELECT * FROM product_hierarchy LIMIT 5
SELECT * FROM product_prices LIMIT 5
*/

/* A. High Level Sales Analysis */


-- 1- What was the total quantity sold for all products?

-- for each product
SELECT prod_id, SUM(qty)
FROM sales
GROUP BY prod_id
--total
SELECT SUM(qty)
FROM sales

-- 2- What is the total generated revenue for all products before discounts?

SELECT SUM(a.revenue) as total_revenue
FROM (
	SELECT prod_id, qty, price, qty * price as revenue
	FROM sales
) a

-- 3- What was the total discount amount for all products?

SELECT SUM(c.discount_price) as discount_amount
FROM (
	SELECT *, b.revenue_normal - b.discount_price as revenue_after_discount
	FROM (
		SELECT a.prod_id, a.qty, a.price, a.revenue_normal, a.discount_percent, a.revenue_normal * a.discount_percent as discount_price
		FROM (
			SELECT prod_id, qty, price, qty * price as revenue_normal, ROUND(discount::numeric/100, 2) as discount_percent
			FROM sales
		) a
	) b
) c

