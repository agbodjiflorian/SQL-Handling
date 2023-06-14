/*
SELECT * FROM plans
SELECT * FROM subscriptions LIMIT 6
*/

/* B. Data Analysis Questions */

-- 1- How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT customer_id) as nb_customer
FROM subscriptions

/*
2- What is the monthly distribution of trial plan start_date values for our dataset 
	- use the start of the month as the group by value
*/

SELECT c.month, c.year, COUNT(c.plan_name) as monthly_distribution
FROM (
	SELECT a.start_date, DATE_PART('month', a.start_date) as month, 
		DATE_PART('year', a.start_date) as year, b.plan_name
	FROM subscriptions a
	JOIN plans b
		ON a.plan_id = b.plan_id
	WHERE b.plan_name = 'trial'
) c
GROUP BY c.month, c.year
ORDER BY c.month, c.year

/*
3- What plan start_date values occur after the year 2020 for our dataset? 
	Show the breakdown by count of events for each plan_name
*/

SELECT c.plan_name, COUNT(c.plan_name) as nb_events
FROM (
	SELECT a.start_date, DATE_PART('month', a.start_date) as month, 
		DATE_PART('year', a.start_date) as year, b.plan_name
	FROM subscriptions a
	JOIN plans b
		ON a.plan_id = b.plan_id
) c
WHERE c.year > 2020
GROUP BY c.plan_name

/*
4- What is the customer count and percentage of customers who have 
	churned rounded to 1 decimal place?
*/

SELECT c.nb_churn, d.nb_total_customer, CAST(c.nb_churn as float)*100/d.nb_total_customer as percentage
FROM (
	SELECT ROW_NUMBER() OVER() as n_row, COUNT(a.customer_id) as nb_churn
	FROM subscriptions a
	JOIN plans b
		ON a.plan_id = b.plan_id
	WHERE b.plan_name = 'churn'
) c
JOIN (
	SELECT ROW_NUMBER() OVER() as nb_row, COUNT(DISTINCT customer_id) as nb_total_customer
	FROM subscriptions
) d
	ON c.n_row = d.nb_row

/*
5- How many customers have churned straight after their initial free trial 
	- what percentage is this rounded to the nearest whole number? 
*/

WITH cte as (
	SELECT a.customer_id, b.plan_name, a.start_date, 
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY a.start_date) as nb_row
	FROM subscriptions a
	JOIN plans b
		ON a.plan_id = b.plan_id
)

SELECT t.nb_churn_customer, t.nb_total_customer, CAST(t.nb_churn_customer as float)*100/t.nb_total_customer as percentage
FROM (
	SELECT COUNT(f.customer_id) as nb_churn_customer, 
		(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) as nb_total_customer
	FROM (
		SELECT c.customer_id, c.plan_name as first_plan, c.start_date as first_subscription_date, 
			d.second_plan, d.second_subscription_date
		FROM cte c
		JOIN (
			SELECT customer_id, plan_name as second_plan, start_date as second_subscription_date, nb_row
			FROM cte
			WHERE nb_row = 2 AND plan_name = 'churn'
			GROUP BY customer_id, plan_name, start_date, nb_row
		) d
			ON c.customer_id = d.customer_id
		WHERE c.nb_row = 1 AND c.plan_name = 'trial'
		GROUP BY c.customer_id, c.plan_name, c.start_date, d.second_plan, d.second_subscription_date
	) f
) t

-- 6- What is the number and percentage of customer plans after their initial free trial?

-- we have to consider only the customers whose previous plans are 'trial'
WITH cte as (
	SELECT a.customer_id, b.plan_name, a.start_date, 
		LAG(b.plan_name) OVER(PARTITION BY a.customer_id ORDER BY a.start_date) as previous_plan
	FROM subscriptions a
	JOIN plans b
		ON a.plan_id = b.plan_id
)

SELECT d.plan_name, d.nb_plans, 
	CAST(d.nb_plans as float)*100/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) as percentage
FROM ( 
	SELECT c.plan_name, COUNT(c.plan_name) as nb_plans
	FROM (
		SELECT customer_id, plan_name, start_date, previous_plan
		FROM cte
		WHERE previous_plan = 'trial'
		GROUP BY customer_id, plan_name, start_date, previous_plan
		ORDER BY customer_id
	) c
	GROUP BY c.plan_name
) d
GROUP BY d.plan_name, d.nb_plans

-- 7- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31

	-- we have to consider the lastest plan avalaibale for each customer at this given date
WITH tempp as (
	SELECT a.customer_id, b.plan_name, a.start_date, 
		ROW_NUMBER() OVER (PARTITION BY a.customer_id ORDER BY a.start_date DESC) as n_row
	FROM subscriptions a
	JOIN plans b
		ON a.plan_id = b.plan_id 
	WHERE a.start_date <= '2020-12-31'
	GROUP BY a.customer_id, b.plan_name, a.start_date
	ORDER BY a.customer_id
) 

SELECT d.plan_name, d.nb_plans, 
	CAST(d.nb_plans as float)*100/(SELECT COUNT(DISTINCT customer_id) FROM tempp) as percentage
FROM ( 
	SELECT plan_name, COUNT(plan_name) as nb_plans
	FROM tempp
	WHERE n_row = 1
	GROUP BY plan_name
) d
GROUP BY d.plan_name, d.nb_plans

-- 8- How many customers have upgraded to an annual plan in 2020?

WITH tempp as (
	SELECT a.customer_id, b.plan_name, a.start_date, 
		ROW_NUMBER() OVER (PARTITION BY a.customer_id ORDER BY a.start_date) as n_row
	FROM subscriptions a
	JOIN plans b
		ON a.plan_id = b.plan_id 
	WHERE DATE_PART('year', a.start_date) = '2020'
	GROUP BY a.customer_id, b.plan_name, a.start_date
	ORDER BY a.customer_id
)

SELECT plan_name, COUNT(*) as nb_upgrade_plan
FROM tempp
WHERE n_row != 1 AND plan_name = 'pro annual'
GROUP BY plan_name

/*
9- How many days on average does it take for a customer to an 
	annual plan from the day they join Foodie-Fi?
*/

WITH cte as (
	SELECT a.customer_id, b.plan_name, a.start_date,
		ROW_NUMBER() OVER (PARTITION BY a.customer_id ORDER BY a.start_date) as n_row
	FROM subscriptions a
	JOIN plans b
		ON a.plan_id = b.plan_id
)

SELECT ROUND(AVG(t.nb_days), 2) as average_day
FROM (
	SELECT m.customer_id, m.plan_name, m.start_date, n.plan_name, n.start_date as annual_date, 
		(n.start_date - m.start_date) as nb_days
	FROM cte m
	JOIN (
		SELECT *
		FROM cte
		WHERE plan_name = 'pro annual'
	) n
		ON m.customer_id = n.customer_id
	WHERE m.n_row = 1
	GROUP BY m.customer_id, m.plan_name, m.start_date, n.plan_name, n.start_date
	ORDER BY m.customer_id
) t

/*
10- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
	* The days between trial start date and the annual plan start date is computed.
	* The days are bucketed in 30 day period by dividing the number of days obtained by 30.
*/

WITH cte as (
	SELECT a.customer_id, b.plan_name, a.start_date,
		ROW_NUMBER() OVER (PARTITION BY a.customer_id ORDER BY a.start_date) as n_row
	FROM subscriptions a
	JOIN plans b
		ON a.plan_id = b.plan_id
)

SELECT CONCAT((s.thirty_day_period*30), '-', (s.thirty_day_period*30)+30) as week_bucket, 
	   COUNT(s.thirty_day_period)
FROM (
	SELECT t.customer_id, t.plan_name, t.start_date, t.pro_plan, t.annual_date, t.nb_days, t.nb_days/30 as thirty_day_period
	FROM (
		SELECT m.customer_id, m.plan_name, m.start_date, n.plan_name as pro_plan, n.start_date as annual_date, 
			(n.start_date - m.start_date) as nb_days
		FROM cte m
		JOIN (
			SELECT *
			FROM cte
			WHERE plan_name = 'pro annual'
		) n
			ON m.customer_id = n.customer_id
		WHERE m.n_row = 1
		GROUP BY m.customer_id, m.plan_name, m.start_date, n.plan_name, n.start_date
		ORDER BY m.customer_id
	) t
	GROUP BY t.customer_id, t.plan_name, t.start_date, t.pro_plan, t.annual_date, t.nb_days
	ORDER BY t.customer_id
)s
GROUP BY s.thirty_day_period

-- 11- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

	-- we have to consider only the customers with 'basic monthly' plan whose previous plans are 'pro monthly'
WITH cte as (
	SELECT a.customer_id, b.plan_name, a.start_date, 
		LAG(b.plan_name) OVER(PARTITION BY a.customer_id ORDER BY a.start_date) as previous_plan
	FROM subscriptions a
	JOIN plans b
		ON a.plan_id = b.plan_id
	WHERE DATE_PART('year', a.start_date) = '2020'
)

SELECT COUNT(c.customer_id) as nb_downgrad
FROM (
	SELECT customer_id, plan_name, start_date, previous_plan
	FROM cte
	WHERE plan_name = 'basic monthly' AND previous_plan = 'pro monthly'
	GROUP BY customer_id, plan_name, start_date, previous_plan
	ORDER BY customer_id
) c
GROUP BY c.customer_id
