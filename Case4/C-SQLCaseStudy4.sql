/*
SELECT * FROM regions LIMIT 5
SELECT * FROM customer_nodes LIMIT 5
SELECT * FROM customer_transactions ORDER BY customer_id LIMIT 5
*/

/* C. Data Allocation Challenge */

-- Option 1: data is allocated based off the amount of money at the end of the previous month
-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
-- Option 3: data is updated real-time

WITH cte as (
	SELECT customer_id, txn_date, DATE_PART('month', txn_date) as month, txn_type, txn_amount
	FROM customer_transactions
	ORDER BY customer_id, txn_date
)

-- running customer balance column that includes impact of each transaction
	
SELECT customer_id, txn_date, txn_type, txn_amount,
	SUM(
		CASE
			WHEN txn_type = 'deposit' THEN txn_amount
			ELSE -1 * txn_amount
		END
	   ) OVER(PARTITION BY customer_id ORDER BY txn_date) as running_balance
FROM cte
GROUP BY customer_id, txn_date, txn_type, txn_amount
ORDER BY customer_id, txn_date

-- customer balance at the end of each month

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

-- minimum, average and maximum values of the running balance for each customer

SELECT a.customer_id, MIN(a.balance) as minimum, 
	ROUND(AVG(a.balance), 2) as average, MAX(a.balance) as maximum
FROM (
	SELECT customer_id, txn_date, txn_type, txn_amount,
		SUM(
			CASE
				WHEN txn_type = 'deposit' THEN txn_amount
				ELSE -1 * txn_amount
			END
		   ) OVER(PARTITION BY customer_id ORDER BY txn_date) as balance
	FROM cte
	GROUP BY customer_id, txn_date, txn_type, txn_amount
	ORDER BY customer_id, txn_date
) a
GROUP BY a.customer_id