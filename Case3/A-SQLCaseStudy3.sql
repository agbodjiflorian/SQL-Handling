/*
SELECT * FROM plans
SELECT * FROM subscriptions LIMIT 6
*/

/* A. Customer Journey */

/*
Based off the 8 sample customers provided in the sample from the 
subscriptions table, write a brief description about each 
customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run 
some sort of join to make your explanations a bit easier!
*/

-- customer 1
SELECT a.customer_id, a.plan_id, a.start_date, b.plan_name, b.price
FROM subscriptions a
JOIN plans b
	ON a.plan_id = b.plan_id
WHERE a.customer_id = 1

-- Description
/*
The Customer 1 started a 7 day free trial on 2020-08-01, 
then after the expiration of his free trial on 2020-08-08, 
instead of continuing with the pro monthly subscription plan 
he cancelled and did downgrade to the basic plan
*/

-- customer 87
SELECT a.customer_id, a.plan_id, a.start_date, b.plan_name, b.price
FROM subscriptions a
JOIN plans b
	ON a.plan_id = b.plan_id
WHERE a.customer_id = 87

-- Description
/*
- started with 7 day free trial
- continue with pro monthly subscription
- upgrade to annual pro plan
*/

