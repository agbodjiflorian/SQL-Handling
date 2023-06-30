/*
SELECT * FROM event_identifier LIMIT 5
SELECT * FROM campaign_identifier LIMIT 5
SELECT * FROM page_hierarchy LIMIT 5
SELECT * FROM users LIMIT 5
SELECT * FROM events LIMIT 5
*/

/* B. Product Funnel Analysis */
/*
DROP TABLE IF EXISTS funnel_analysis
CREATE TABLE funnel_analysis AS
*/
/*
How many times was each product viewed?
How many times was each product added to cart?
How many times was each product added to a cart but not purchased (abandoned)?
How many times was each product purchased?
*/

WITH cte as (
	SELECT a.page_id, a.product_id, a.page_name, b.visit_id, 
		b.cookie_id, b.event_type, c.event_name, CASE WHEN d.purchase = 1 THEN 1 ELSE 0 END as purchase
	FROM page_hierarchy a
	LEFT JOIN (SELECT * FROM events) b ON a.page_id = b.page_id
	LEFT JOIN (SELECT * FROM event_identifier) c ON b.event_type = c.event_type
	LEFT JOIN (
		SELECT DISTINCT visit_id, event_type, 1 as purchase FROM events WHERE event_type = 3
	) d ON b.visit_id = d.visit_id AND b.event_type = d.event_type
)
--SELECT * FROM cte WHERE purchase = 1

SELECT i.page_name, 
	SUM (CASE WHEN i.event_type = 1 THEN 1 ELSE 0 END) as nb_views,
	SUM (CASE WHEN i.event_type = 2 THEN 1 ELSE 0 END) as nb_adds,
	SUM (i.purchase) as nb_purchase
FROM cte i
WHERE i.product_id IS NOT NULL
GROUP BY i.page_name



