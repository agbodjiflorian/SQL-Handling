/*
SELECT * FROM product_details LIMIT 5
SELECT * FROM sales LIMIT 5
SELECT * FROM product_hierarchy LIMIT 5
SELECT * FROM product_prices LIMIT 5
*/

/* B. Transaction Analysis */

-- 1- How many unique transactions were there?

SELECT COUNT(DISTINCT txn_id)
FROM sales

-- 2- What is the average unique products purchased in each transaction?

SELECT AVG(a.nb)
FROM (
	SELECT txn_id, COUNT(DISTINCT prod_id) as nb
	FROM sales
	GROUP BY txn_id
) a

-- 3- What are the 25th, 50th and 75th percentile values for the revenue per transaction?

SELECT PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY c.revenue_after_discount), 
	PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY c.revenue_after_discount),
	PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY c.revenue_after_discount)
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

-- 4- What is the average discount value per transaction?

SELECT ROUND(AVG(c.discount_price), 2)
FROM (
	SELECT *, b.revenue_normal - b.discount_price as revenue_after_discount
	FROM (
		SELECT a.prod_id, a.qty, a.price, a.revenue_normal, a.discount_percent, a.revenue_normal * a.discount_percent as discount_price, a.txn_id
		FROM (
			SELECT prod_id, qty, price, qty * price as revenue_normal, ROUND(discount::numeric/100, 2) as discount_percent, txn_id
			FROM sales
		) a
	) b
) c

-- 5- What is the percentage split of all transactions for members vs non-members?

SELECT ROUND(100* (SUM(CASE WHEN member IS true THEN 1 ELSE 0 END))::numeric/COUNT(member), 2) as members,
	ROUND(100* (SUM(CASE WHEN member IS NOT true THEN 1 ELSE 0 END))::numeric/COUNT(member), 2) as non_members
FROM sales

-- 6- What is the average revenue for member transactions and non-member transactions?

SELECT c.member, ROUND(AVG(revenue_after_discount), 2) 
FROM (
	SELECT *, b.revenue_normal - b.discount_price as revenue_after_discount
	FROM (
		SELECT a.prod_id, a.qty, a.price, a.revenue_normal, a.discount_percent, a.revenue_normal * a.discount_percent as discount_price, a.member
		FROM (
			SELECT prod_id, qty, price, qty * price as revenue_normal, ROUND(discount::numeric/100, 2) as discount_percent, member
			FROM sales
		) a
	) b
) c
GROUP BY c.member
