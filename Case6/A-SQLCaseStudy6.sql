/*
SELECT * FROM event_identifier LIMIT 5
SELECT * FROM campaign_identifier LIMIT 5
SELECT * FROM page_hierarchy LIMIT 5
SELECT * FROM users LIMIT 5
SELECT * FROM events LIMIT 5
*/

/* A. Digital Analysis */

-- 1- How many users are there?

SELECT COUNT(DISTINCT user_id)
FROM users

-- 2- How many cookies does each user have on average?

SELECT ROUND(AVG(a.nb_cookie), 0) as average
FROM (
SELECT user_id, COUNT(cookie_id) as nb_cookie
FROM users
GROUP BY user_id
) a

-- 3- What is the unique number of visits by all users per month?

SELECT b.month, COUNT(DISTINCT b.visit_id)
FROM (
	SELECT *, DATE_PART('month', event_time) as month
	FROM events
) b
GROUP BY b.month

-- 4- What is the number of events for each event type?

SELECT a.event_type, a.event_name, COUNT(b.event_type)
FROM event_identifier a
JOIN (
	SELECT *
	FROM events
) b
	ON a.event_type = b.event_type
GROUP BY a.event_type, a.event_name

-- 5- What is the percentage of visits which have a purchase event?

SELECT ROUND(100*(SELECT COUNT(DISTINCT visit_id) FROM events WHERE event_type = 3)::numeric / 
			 (COUNT(DISTINCT visit_id)))
FROM events

-- 6- What is the percentage of visits which view the checkout page but do not have a purchase event?

SELECT ROUND(100*(SELECT COUNT(DISTINCT visit_id) FROM events WHERE page_id = 12 AND event_type != 3)::numeric / 
			 (COUNT(DISTINCT visit_id)), 2)
FROM events

-- 7- What are the top 3 pages by number of views?

SELECT page_id, COUNT(visit_id)
FROM events
GROUP BY page_id
ORDER BY COUNT(visit_id) DESC LIMIT 3

-- 8- What is the number of views and cart adds for each product category?

SELECT e.product_category, SUM(e.nb_views) as nb_views, SUM(e.nb_add) as nb_add
FROM (
	SELECT DISTINCT a.page_id as page_id, b.nb_views, c.nb_add, d.product_category
	FROM events a
	LEFT JOIN (
		SELECT page_id, COUNT(event_type) as nb_views
		FROM events
		WHERE event_type = 1
		GROUP BY page_id
	) b
		ON a.page_id = b.page_id	
	LEFT JOIN (
		SELECT page_id, COUNT(event_type) as nb_add
		FROM events
		WHERE event_type = 2
		GROUP BY page_id
	) c
		ON a.page_id = c.page_id
	LEFT JOIN (
		SELECT * FROM page_hierarchy
	) d
		ON a.page_id = d.page_id
	GROUP BY a.page_id, b.nb_views, c.nb_add, d.product_category
	ORDER BY a.page_id
) e
GROUP BY e.product_category

-- 9- What are the top 3 products by purchases?


