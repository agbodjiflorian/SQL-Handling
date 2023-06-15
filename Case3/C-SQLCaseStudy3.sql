/*
SELECT * FROM plans
SELECT * FROM subscriptions LIMIT 6
*/

/* C. Challenge Payment Question */

/*
The Foodie-Fi team wants you to create a new payments table for 
the year 2020 that includes amounts paid by each customer in 
the subscriptions table with the following requirements:

	- monthly payments always occur on the same day of month as 
		the original start_date of any monthly paid plan
		
	- upgrades from basic to monthly or pro plans are reduced by
		the current paid amount in that month and start immediately
		
	- upgrades from pro monthly to pro annual are paid at the end of
		the current billing period and also starts at the end of the month period
		
	- once a customer churns they will no longer make payments
*/

-- get all the plan made in 2020 without the trial plan
-- get the next plan and the date of the next plan made by each customer

/* select : all the customers' id, their plans' names without the churn plan
	considering that once a customer churns they will no longer make payments, 
	and the start date of their next plan */
DROP TABLE IF EXISTS payments
CREATE TABLE payments AS
WITH RECURSIVE cte as (
	SELECT d.customer_id, d.plan_id, d.plan_name, d.payment_date, d.next_plan as np, d.next_plan_date, d.next_plan,
		COALESCE(d.next_plan_date, '2020/12/31') as cut_date, d.amount
	FROM (
		SELECT a.customer_id, b.plan_id, b.plan_name, a.start_date as payment_date, b.price as amount,
			LEAD(b.plan_name) OVER(PARTITION BY a.customer_id ORDER BY a.start_date) as next_plan,
			LEAD(a.start_date) OVER(PARTITION BY a.customer_id ORDER BY a.start_date) as next_plan_date
		FROM subscriptions a
		JOIN plans b
			ON a.plan_id = b.plan_id
		WHERE DATE_PART('year', a.start_date) = '2020' 
			AND b.plan_name IN ('basic monthly', 'churn', 'pro monthly', 'pro annual')
	) d
	WHERE d.plan_name != 'churn'
	GROUP BY d.customer_id, d.plan_id, d.plan_name, d.payment_date, d.amount, d.next_plan, d.next_plan_date	
),

tempp as (
	SELECT customer_id, plan_id, plan_name, payment_date, next_plan, next_plan_date, 
		CASE 
			WHEN cut_date < ('2020/12/31')::date 
				AND (plan_name = 'pro monthly') THEN ('2020/12/31')::date
			ELSE cut_date
		END as cut_date, amount
	FROM cte
	
	UNION 
	
	SELECT customer_id, plan_id, plan_name, (payment_date + INTERVAL '1 month')::date as payment_date, 
		next_plan, next_plan_date, cut_date, amount
	FROM tempp 
	WHERE (payment_date + INTERVAL '1 month')::date < cut_date AND plan_name != 'pro annual'
)

SELECT j.customer_id, j.plan_id, j.plan_name, j.payment_date, j.cut_date,
	CASE
		WHEN (j.prev_plan = 'basic monthly' OR j.prev_plan = 'pro monthly') 
			AND j.n_row = 1 THEN j.amount - j.prev_plan_amount 
		ELSE j.amount
	END as new_amount
FROM (
	SELECT customer_id, plan_id, plan_name, payment_date, next_plan, cut_date, amount,
		LAG(plan_name) OVER(PARTITION BY customer_id ORDER BY payment_date) as prev_plan,
		LAG(amount) OVER(PARTITION BY customer_id ORDER BY payment_date) as prev_plan_amount,
		ROW_NUMBER() OVER(PARTITION BY customer_id, plan_id ORDER BY payment_date) as n_row 
	FROM tempp
	ORDER BY customer_id, payment_date
) j
GROUP BY j.customer_id, j.plan_id, j.plan_name, j.payment_date,
	j.cut_date, j.amount, j.n_row, j.prev_plan, j.prev_plan_amount
ORDER BY j.customer_id, j.payment_date

SELECT * FROM payments