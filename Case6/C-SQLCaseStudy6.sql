/*
SELECT * FROM event_identifier LIMIT 5
SELECT * FROM campaign_identifier LIMIT 5
SELECT * FROM page_hierarchy LIMIT 5
SELECT * FROM users LIMIT 5
SELECT * FROM events LIMIT 5
*/

/* C. Campaigns Analysis */

DROP TABLE IF EXISTS analysis
CREATE TABLE analysis AS

SELECT DISTINCT a.visit_id, b.user_id, c.visit_start_time, d.page_views, e.cart_adds, 
	CASE WHEN n.purchase_id IS NOT NULL THEN 1 ELSE 0 END as purchase, j.campaign_name,
	k.impression, m.click, p.cart_products
FROM events a
LEFT JOIN (
	SELECT * FROM users
) b
	ON a.cookie_id = b.cookie_id
LEFT JOIN (
	SELECT visit_id, MIN(event_time) as visit_start_time
	FROM events
	GROUP BY visit_id
) c
	ON a.visit_id = c.visit_id
LEFT JOIN (
	SELECT DISTINCT visit_id, COUNT(event_type) as page_views
	FROM events
	WHERE event_type = 1
	GROUP BY visit_id
) d
	ON a.visit_id = d.visit_id
LEFT JOIN (
	SELECT DISTINCT visit_id, COUNT(event_type) as cart_adds
	FROM events
	WHERE event_type = 2
	GROUP BY visit_id
) e
	ON a.visit_id = e.visit_id
LEFT JOIN (
	SELECT DISTINCT visit_id as purchase_id
	FROM events
	WHERE event_type = 3
) n
	ON a.visit_id = n.purchase_id
LEFT JOIN (
	SELECT i.visit_id, i.visit_start_time, 
		CASE
			WHEN i.visit_start_time BETWEEN 
				(SELECT start_date FROM campaign_identifier WHERE campaign_id = 1) AND
				(SELECT end_date FROM campaign_identifier WHERE campaign_id = 1) 
				THEN 'BOGOF - Fishing For Compliments' 
			WHEN i.visit_start_time BETWEEN 
				(SELECT start_date FROM campaign_identifier WHERE campaign_id = 2) AND
				(SELECT end_date FROM campaign_identifier WHERE campaign_id = 2)
				THEN '25% Off - Living The Lux Life'
			WHEN i.visit_start_time BETWEEN 
				(SELECT start_date FROM campaign_identifier WHERE campaign_id = 3) AND
				(SELECT end_date FROM campaign_identifier WHERE campaign_id = 3)
				THEN 'Half Off - Treat Your Shellf(ish)'
		END as campaign_name
	FROM (
		SELECT visit_id, MIN(event_time) as visit_start_time
		FROM events
		GROUP BY visit_id
	) i
) j
	ON a.visit_id = j.visit_id
LEFT JOIN (
	SELECT DISTINCT visit_id, COUNT(event_type) as impression
	FROM events
	WHERE event_type = 4
	GROUP BY visit_id
) k
	ON a.visit_id = k.visit_id
LEFT JOIN (
	SELECT DISTINCT visit_id, COUNT(event_type) as click
	FROM events
	WHERE event_type = 5
	GROUP BY visit_id
) m
	ON a.visit_id = m.visit_id
LEFT JOIN(
	SELECT s.visit_id, string_agg(s.page_name, ', ' ORDER BY s.sequence_number) as cart_products
	FROM (
		SELECT v.visit_id, v.event_type, v.page_id, v.sequence_number, x.page_name
		FROM events v
		JOIN (SELECT * FROM page_hierarchy) x ON x.page_id = v.page_id
		WHERE v.event_type = 2  AND x.product_id IS NOT NULL
		ORDER BY v.visit_id
	) s
	GROUP BY s.visit_id
) p
	ON a.visit_id = p.visit_id
ORDER BY b.user_id

--view
SELECT * FROM analysis
