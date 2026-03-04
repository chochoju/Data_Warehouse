-- MARTS LAYER (VIEWS FOR BI)

CREATE SCHEMA IF NOT EXISTS mart;

-- Daily GMV + Orders
CREATE OR REPLACE VIEW mart.daily_gmv AS
SELECT
	fo.order_purchase_ts::date AS order_date,
	COUNT(DISTINCT fo.order_id) AS orders,
	COUNT(*) FILTER (WHERE fo.order_status = 'delivered') AS delivered_orders,
	SUM(COALESCE(oi.price,0) + COALESCE(oi.freight_value,0)) AS gmv,
	SUM(COALESCE(oi.price,0)) AS item_revenue,
	SUM(COALESCE(oi.freight_value,0)) AS freight_revenue,
	AVG(SUM(COALESCE(oi.price,0) + COALESCE(oi.freight_value,0)))
		OVER(ORDER BY fo.order_purchase_ts::date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS gmv_7d_avg	
FROM dw.fact_order fo
JOIN dw.fact_order_item oi
	ON oi.order_id = fo.order_id
WHERE fo.order_purchase_ts IS NOT NULL
GROUP BY fo.order_purchase_ts::date;


-- Category Performance
CREATE OR REPLACE VIEW mart.category_sales AS
SELECT
	COALESCE(dp.category_en, dp.category_pt, 'unknown') AS category,
	fo.order_purchase_ts::date AS order_date,
	COUNT(DISTINCT fo.order_id) AS orders,
	SUM(COALESCE(oi.price,0)) AS item_revenue,
	SUM(COALESCE(oi.freight_value,0)) AS freight_revenue,
	SUM(COALESCE(oi.price,0) + COALESCE(oi.freight_value,0)) AS gmv,
	COUNT(*) AS items_sold
FROM dw.fact_order fo
JOIN dw.fact_order_item oi
	ON oi.order_id = fo.order_id
JOIN dw.dim_product dp
	ON dp.product_key = oi.product_key
WHERE fo.order_purchase_ts IS NOT NULL
GROUP BY 1, 2;


-- Delivery SLA overview (delivery speed & on-time %)
CREATE OR REPLACE VIEW mart.delivery_sla AS
SELECT
	fo.order_purchase_ts::date AS order_date,
	COUNT(*) FILTER(WHERE fo.order_status = 'delivered') AS delivered_orders,
	AVG(fo.delivery_days_actual) FILTER(WHERE fo.delivery_days_actual IS NOT NULL) AS avg_delivery_days,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fo.delivery_days_actual)
		FILTER(WHERE fo.delivery_days_actual IS NOT NULL) AS median_delivery_days,
	AVG(
		CASE 
		  WHEN fo.delivered_customer_ts IS NOT NULL AND fo.estimated_delivery_ts IS NOT NULL
		    AND fo.delivered_customer_ts::date <= fo.estimated_delivery_ts::date
			  THEN 1.0
		  WHEN fo.delivered_customer_ts IS NOT NULL AND fo.estimated_delivery_ts IS NOT NULL
		      THEN 0.0
		  ELSE NULL
		END
	) AS on_time_rate
FROM dw.fact_order fo
WHERE fo.order_purchase_ts IS NOT NULL
GROUP BY fo.order_purchase_ts::date;


-- Customer Repeat Behavior (new vs returning vs loyal)
CREATE OR REPLACE VIEW mart.customer_segments_monthly AS
WITH customer_orders AS (
	SELECT
		dc.customer_key,
		DATE_TRUNC('month', fo.order_purchase_ts)::date AS month,
		COUNT(DISTINCT fo.order_id) AS orders_in_month
	FROM dw.fact_order fo
	JOIN dw.dim_customer dc 
		ON dc.customer_key = fo.customer_key
	WHERE fo.order_purchase_ts IS NOT NULL
	GROUP BY 1, 2
),
lifetime_orders AS (
	SELECT
		dc.customer_key, COUNT(DISTINCT fo.order_id) AS lifetime_orders
	FROM dw.fact_order fo
	JOIN dw.dim_customer dc
		ON dc.customer_key = fo.customer_key
	GROUP BY 1
)
SELECT
	co.month,
	CASE
	  WHEN lo.lifetime_orders = 1 THEN 'New'
	  WHEN lo.lifetime_orders BETWEEN 2 AND 5 THEN 'Returning'
	  WHEN lo.lifetime_orders <= 6 THEN 'Loyal'
		ELSE 'Unknown'
	END AS customer_segment,
	COUNT(DISTINCT co.customer_key) AS customers,
	SUM(co.orders_in_month) AS orders
FROM customer_orders co
JOIN lifetime_orders lo
	ON lo.customer_key = co.customer_key
GROUP BY 1, 2;


-- Payment Mix (GMV by payment type)
CREATE OR REPLACE VIEW mart.payment_mix_daily AS
WITH daily_payments AS (
	SELECT
		fo.order_purchase_ts::date AS order_date,
		dpt.payment_type,
		SUM(COALESCE(fp.payment_value,0)) AS payment_value
	FROM dw.fact_payment fp
	JOIN dw.fact_order fo 
		ON fo.order_id = fp.order_id
	JOIN dw.dim_payment_type dpt
		ON dpt.payment_type_key = fp.payment_type_key
	WHERE fo.order_purchase_ts IS NOT NULL
	GROUP BY 1, 2
),
totals AS (
	SELECT order_date, SUM(payment_value) AS total_payment_value
	FROM daily_payments
	GROUP BY 1
)
SELECT
	dp.order_date,
	dp.payment_type,
	dp.payment_value,
	t.total_payment_value,
	CASE
	  WHEN t.total_payment_value > 0
	  	THEN dp.payment_value / t.total_payment_value
	  ELSE NULL
	END AS payment_share
FROM daily_payments dp
JOIN totals t ON t.order_date = dp.order_date;


-- Seller Performance (GMV, orders, delivery score)
CREATE OR REPLACE VIEW mart.seller_performance_monthly AS
WITH seller_gmv AS (
	SELECT
		ds.seller_key,
		DATE_TRUNC('month', fo.order_purchase_ts)::date AS month,
		COUNT(DISTINCT fo.order_id) AS orders,
		SUM(COALESCE(oi.price,0) + COALESCE(oi.freight_value,0)) AS gmv
	FROM dw.fact_order fo
	JOIN dw.fact_order_item oi
		ON oi.order_id = fo.order_id
	JOIN dw.dim_seller ds
		ON ds.seller_key = oi.seller_key
	WHERE fo.order_purchase_ts IS NOT NULL
	GROUP BY 1, 2
),
seller_reviews AS (
	SELECT
		oi.seller_key,
		DATE_TRUNC('month', fo.order_purchase_ts)::date AS month,
		AVG(fr.review_score) AS avg_review_score
	FROM dw.fact_order fo
	JOIN dw.fact_order_item oi
		ON oi.order_id = fo.order_id
	LEFT JOIN dw.fact_review fr
		ON fr.order_id = fo.order_id
	WHERE fo.order_purchase_ts IS NOT NULL
	GROUP BY 1, 2
)
SELECT
	sg.month,
	ds.seller_id,
	sg.orders,
	sg.gmv,
	sr.avg_review_score
FROM seller_gmv sg
JOIN dw.dim_seller ds 
	ON ds.seller_key = sg.seller_key
LEFT JOIN seller_reviews sr
	ON sr.seller_key = sg.seller_key AND sr.month = sg.month;


-- GMV by Customer State (geo mart)
CREATE OR REPLACE VIEW mart.gmv_by_customer_state AS
SELECT
	dc.state AS state,
	fo.order_purchase_ts::date AS order_date,
	SUM(COALESCE(oi.price,0)+COALESCE(oi.freight_value,0)) AS gmv,
	COUNT(DISTINCT fo.order_id) AS orders
FROM dw.fact_order fo
JOIN dw.fact_order_item oi ON oi.order_id = fo.order_id
JOIN dw.dim_customer dc ON dc.customer_key = fo.customer_key
WHERE fo.order_purchase_ts IS NOT NULL
GROUP BY dc.state, fo.order_purchase_ts::date;


-- Seller by State (geo mart)
CREATE OR REPLACE VIEW mart.sellers_by_state AS
SELECT state, COUNT(DISTINCT seller_id) AS sellers
FROM dw.dim_seller
GROUP BY state;
