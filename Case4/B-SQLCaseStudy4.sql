/*
SELECT * FROM regions LIMIT 5
SELECT * FROM customer_nodes LIMIT 5
SELECT * FROM customer_transactions ORDER BY customer_id LIMIT 5
*/

/* B. Customer Transactions */

-- 1- What is the unique count and total amount for each transaction type?
SELECT txn_type, COUNT(txn_type), SUM(txn_amount) as total_amount
FROM customer_transactions
GROUP BY txn_type

-- 2- What is the average total historical deposit counts and amounts for all customers?

SELECT ROUND(AVG(a.nb_deposit), 2) as average_deposit, 
	ROUND(AVG(a.average_deposit_amount_each_customer), 2) as  average_deposit_amount
FROM (
	SELECT customer_id, txn_type, COUNT(txn_type) as nb_deposit, 
			ROUND(AVG(txn_amount), 2) as average_deposit_amount_each_customer
	FROM customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id, txn_type
	ORDER BY customer_id
) a

/* 3- For each month - how many Data Bank customers make more 
	than 1 deposit and either 1 purchase or 1 withdrawal in a single month? */
	
WITH cte as (
	SELECT customer_id, txn_date, DATE_PART('month', txn_date) as month, txn_type
	FROM customer_transactions
	--GROUP BY customer_id, DATE_PART('month', txn_date), txn_date, txn_type
	ORDER BY customer_id, txn_date
) 

SELECT e.month, COUNT(e.customer_id) as nb
FROM (
	SELECT d.month, d.customer_id, d.nb_deposit, d.nb_purchase, d.nb_withdrawal
	FROM (
		SELECT a.month, a.customer_id, COUNT(a.txn_type) as nb_deposit, b.nb_purchase, c.nb_withdrawal
		FROM cte a
		LEFT JOIN (
			SELECT month, customer_id, COUNT(txn_type) as nb_purchase
			FROM cte
			WHERE txn_type = 'purchase'
			GROUP BY month, customer_id, txn_type
		) b
			ON a.customer_id = b.customer_id AND a.month = b.month
		LEFT JOIN (
			SELECT month, customer_id, COUNT(txn_type) as nb_withdrawal
			FROM cte
			WHERE txn_type = 'withdrawal'
			GROUP BY month, customer_id, txn_type
		) c
			ON c.customer_id = a.customer_id AND c.month = a.month
		WHERE a.txn_type = 'deposit'
		GROUP BY a.month, a.customer_id, a.txn_type, b.nb_purchase, c.nb_withdrawal
	) d
	WHERE d.nb_deposit > 1 AND (d.nb_purchase = 1 OR d.nb_withdrawal = 1)
	--WHERE (d.nb_deposit > 1 AND d.nb_purchase = 1) OR (d.nb_deposit > 1 AND d.nb_withdrawal = 1)
	GROUP BY d.month, d.customer_id, d.nb_deposit, d.nb_purchase, d.nb_withdrawal
) e
GROUP BY e.month

-- 4- What is the closing balance for each customer at the end of the month?

WITH cte as (
	SELECT customer_id, txn_date, DATE_PART('month', txn_date) as month, txn_type, txn_amount
	FROM customer_transactions
	ORDER BY customer_id, txn_date
) 

SELECT f.month, f.customer_id, f.balance, 
	SUM(f.balance) OVER(PARTITION BY f.customer_id ORDER BY f.month) as closing_balance
FROM (
	SELECT customer_id, month, 
	SUM(
		CASE
			WHEN txn_type = 'deposit' THEN txn_amount
			ELSE -1 * txn_amount
		END
	   ) as balance
	FROM cte
	GROUP BY customer_id, month
	ORDER BY customer_id, month
) f
GROUP BY f.month, f.customer_id, f.balance
ORDER BY f.customer_id, f.month

-- 5- What is the percentage of customers who increase their closing balance by more than 5%?

WITH cte as (
	SELECT customer_id, txn_date, DATE_PART('month', txn_date) as month, txn_type, txn_amount
	FROM customer_transactions
	ORDER BY customer_id, txn_date
),
 
increase as (
	SELECT g.month, g.customer_id, g.closing_balance, 
		LEAD(g.closing_balance) OVER(PARTITION BY g.customer_id ORDER BY g.month) as next_balance
	FROM (
		SELECT f.month, f.customer_id, f.balance, 
			SUM(f.balance) OVER(PARTITION BY f.customer_id ORDER BY f.month) as closing_balance
		FROM (
			SELECT customer_id, month, 
			SUM(
				CASE
					WHEN txn_type = 'deposit' THEN txn_amount
					ELSE -1 * txn_amount
				END
			   ) as balance
			FROM cte
			GROUP BY customer_id, month
			ORDER BY customer_id, month
		) f
		GROUP BY f.month, f.customer_id, f.balance
		ORDER BY f.customer_id, f.month
	) g
	GROUP BY g.month, g.customer_id, g.closing_balance
	ORDER BY g.customer_id, g.month
)

SELECT ROUND(j.nb::numeric/j.total * 100, 2) as percentage
FROM (
	SELECT COUNT(DISTINCT i.customer_id) as nb, (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions) as total
	FROM (
		SELECT t.month, t.customer_id, t.incre
		FROM (
			SELECT h.month, h.customer_id, h.closing_balance, h.next_balance, 
				ROUND(((h.next_balance - h.closing_balance)/NULLIF(h.closing_balance, 0))*100, 2) as incre
			FROM increase h
		) t
		WHERE t.incre > 5
	) i
) j
