-- DW LAYER (STAR SCHEMA + LOADS)

-- 1) DIMENSIONS

-- Customer dimension
DROP TABLE IF EXISTS dw.dim_customer CASCADE;
CREATE TABLE dw.dim_customer (
	customer_key		bigserial PRIMARY KEY,
	customer_id			text NOT NULL UNIQUE,
	customer_unique_id	text,
	zip_code_prefix		integer,
	city				text,
	state				text
);

-- Seller dimension
DROP TABLE IF EXISTS dw.dim_seller CASCADE;
CREATE TABLE dw.dim_seller (
	seller_key		bigserial PRIMARY KEY,
	seller_id		text NOT NULL UNIQUE,
	zip_code_prefix	integer,
	city			text,
	state			text
);

-- Product dimension
DROP TABLE IF EXISTS dw.dim_product CASCADE;
CREATE TABLE dw.dim_product (
	product_key		bigserial PRIMARY KEY,
	product_id		text NOT NULL UNIQUE,
	category_pt		text,
	category_en		text,
	weight_g		integer,
	length_cm		integer,
	height_cm		integer,
	width_cm		integer
);

-- Payment Type dimension
DROP TABLE IF EXISTS dw.dim_payment_type CASCADE;
CREATE TABLE dw.dim_payment_type (
	payment_type_key	bigserial PRIMARY KEY,
	payment_type		text NOT NULL UNIQUE
);

-- 2) FACTS

-- Order fact (grain: 1 row per order)
DROP TABLE IF EXISTS dw.fact_order CASCADE;
CREATE TABLE dw.fact_order (
	order_id				text PRIMARY KEY,
	customer_key			bigint NOT NULL REFERENCES dw.dim_customer(customer_key),
	order_status			text NOT NULL,
	order_purchase_ts		timestamp,
	order_approved_ts		timestamp,
	delivered_carrier_ts	timestamp,
	delivered_customer_ts	timestamp,
	estimated_delivery_ts	timestamp,
	delivery_days_actual	integer
);

-- Order Item fact (grain: 1 row per order item line)
DROP TABLE IF EXISTS dw.fact_order_item CASCADE;
CREATE TABLE dw.fact_order_item (
	order_item_key		bigserial PRIMARY KEY,
	order_id			text NOT NULL REFERENCES dw.fact_order(order_id),
	order_item_id		integer NOT NULL,
	product_key			bigint NOT NULL REFERENCES dw.dim_product(product_key),
	seller_key			bigint NOT NULL REFERENCES dw.dim_seller(seller_key),
	shipping_limit_ts	timestamp,
	price				numeric(12,2),
	freight_value		numeric(12,2)
);

-- Payment fact (grain: 1 row per payment record)
DROP TABLE IF EXISTS dw.fact_payment CASCADE;
CREATE TABLE dw.fact_payment (
	payment_key				bigserial PRIMARY KEY,
	order_id				text NOT NULL REFERENCES dw.fact_order(order_id),
	payment_type_key		bigint NOT NULL REFERENCES dw.dim_payment_type(payment_type_key),
	payment_sequential		integer NOT NULL,
	payment_installments	integer,
	payment_value			numeric(12,2)
);

-- Review fact (grain: 1 row per review)
DROP TABLE IF EXISTS dw.fact_review CASCADE;
CREATE TABLE dw.fact_review (
	review_id			text PRIMARY KEY,
	order_id			text NOT NULL REFERENCES dw.fact_order(order_id),
	review_score		smallint,
	review_creation_ts	timestamp,
	review_answer_ts	timestamp
);


-- 3) LOAD DIMENSIONS

-- Clear DW tables (truncate facts first, then dims)
TRUNCATE TABLE
  dw.fact_review,
  dw.fact_payment,
  dw.fact_order_item,
  dw.fact_order,
  dw.dim_payment_type,
  dw.dim_product,
  dw.dim_seller,
  dw.dim_customer
RESTART IDENTITY;

SELECT COUNT(*) FROM dw.dim_customer;

-- dim_customer
INSERT INTO dw.dim_customer (customer_id, customer_unique_id, zip_code_prefix, city, state)
SELECT 
	c.customer_id,
  	c.customer_unique_id,
  	c.zip_code_prefix,
  	c.city,
  	c.state
FROM stg.customers c;

-- dim_seller
INSERT INTO dw.dim_seller (seller_id, zip_code_prefix, city, state)
SELECT
	s.seller_id,
	s.zip_code_prefix,
	s.city,
	s.state
FROM stg.sellers s;

-- dim_product
INSERT INTO dw.dim_product (product_id, category_pt, category_en, weight_g, length_cm, height_cm, width_cm)
SELECT
	p.product_id,
	p.product_category_name AS category_pt,
	ct.product_category_name_english AS category_en,
	p.product_weight_g AS weight_g,
	p.product_length_cm AS length_cm,
	p.product_height_cm AS height_cm,
	p.product_width_cm AS width_cm
FROM stg.products p
LEFT JOIN stg.category_translation ct
	ON ct.product_category_name = p.product_category_name;

-- dim_payment_type
INSERT INTO dw.dim_payment_type (payment_type)
SELECT DISTINCT p.payment_type
FROM stg.payments p
WHERE p.payment_type IS NOT NULL;

-- 4) LOAD FACTS

-- fact_order
INSERT INTO dw.fact_order (
	order_id, customer_key, order_status,
	order_purchase_ts, order_approved_ts,
  	delivered_carrier_ts, delivered_customer_ts, estimated_delivery_ts,
  	delivery_days_actual
)
SELECT
	o.order_id,
	dc.customer_key,
	o.order_status,
	o.order_purchase_ts,
  	o.order_approved_ts,
  	o.delivered_carrier_ts,
  	o.delivered_customer_ts,
  	o.estimated_delivery_ts,
	CASE
		WHEN o.delivered_customer_ts IS NOT NULL AND o.order_purchase_ts IS NOT NULL
			THEN (o.delivered_customer_ts::date - o.order_purchase_ts::date)
		ELSE NULL
	END AS delivery_days_actual
FROM stg.orders o
JOIN dw.dim_customer dc
	ON dc.customer_id = o.customer_id;

-- fact_order_item
INSERT INTO dw.fact_order_item (
	order_id, order_item_id, product_key, seller_key,
  	shipping_limit_ts, price, freight_value
)
SELECT
	i.order_id,
	i.order_item_id,
	dp.product_key,
	ds.seller_key,
	i.shipping_limit_ts,
	i.price,
	i.freight_value
FROM stg.order_items i
JOIN dw.fact_order fo
	ON fo.order_id = i.order_id
JOIN dw.dim_product dp
	ON dp.product_id = i.product_id
JOIN dw.dim_seller ds
	ON ds.seller_id = i.seller_id;

-- fact_payment
INSERT INTO dw.fact_payment (
	order_id, payment_type_key, payment_sequential,
  	payment_installments, payment_value
)
SELECT
	p.order_id,
	dpt.payment_type_key,
	p.payment_sequential,
	p.installments,
	p.payment_value
FROM stg.payments p
JOIN dw.fact_order fo
	ON fo.order_id = p.order_id
JOIN dw.dim_payment_type dpt
	ON dpt.payment_type = p.payment_type;

-- fact_review
INSERT INTO dw.fact_review (
	review_id, order_id, review_score, 
	review_creation_ts, review_answer_ts
)
SELECT
	r.review_id,
	r.order_id,
	r.review_sccore,
	r.review_creation_ts,
	r.review_answer_ts
FROM stg.reviews r
JOIN dw.fact_order fo
	ON fo.order_id = r.order_id;


-- 4) BASIC INDEXES
CREATE INDEX IF NOT EXISTS ix_fact_order_customer_key ON dw.fact_order(customer_key);
CREATE INDEX IF NOT EXISTS ix_fact_order_purchase_ts ON dw.fact_order(order_purchase_ts);
CREATE INDEX IF NOT EXISTS ix_fact_item_order_id ON dw.fact_order_item(order_id);
CREATE INDEX IF NOT EXISTS ix_fact_item_product_key ON dw.fact_order_item(product_key);
CREATE INDEX IF NOT EXISTS ix_fact_item_seller_key ON dw.fact_order_item(seller_key);
CREATE INDEX IF NOT EXISTS ix_fact_payment_order_id ON dw.fact_payment(order_id);
CREATE INDEX IF NOT EXISTS ix_fact_review_order_id ON dw.fact_review(order_id);


-- 5) SANITY CHECK
SELECT 'dim_customer' AS t, COUNT(*) FROM dw.dim_customer
UNION ALL SELECT 'dim_product', COUNT(*) FROM dw.dim_product
UNION ALL SELECT 'fact_order', COUNT(*) FROM dw.fact_order
UNION ALL SELECT 'fact_order_item', COUNT(*) FROM dw.fact_order_item
UNION ALL SELECT 'fact_payment', COUNT(*) FROM dw.fact_payment
UNION ALL SELECT 'fact_review', COUNT(*) FROM dw.fact_review;


