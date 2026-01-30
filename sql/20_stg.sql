-- STAGING LAYER

-- stg.customers
DROP TABLE IF EXISTS stg.customers;
CREATE TABLE stg.customers (
	customer_id			text PRIMARY KEY,
	customer_unique_id	text,
	zip_code_prefix		integer,
	city				text,
	state				text
);

INSERT INTO stg.customers (customer_id, customer_unique_id, zip_code_prefix, city, state)
SELECT DISTINCT ON (TRIM(customer_id))
	TRIM(customer_id) AS customer_id,
	NULLIF(TRIM(customer_unique_id), '') AS customer_unique_id,
	NULLIF(TRIM(customer_zip_code_prefix), '')::integer AS zip_code_prefix,
	NULLIF(TRIM(customer_city), '') AS city,
	NULLIF(TRIM(customer_state), '') AS state
FROM raw.olist_customers
WHERE NULLIF(TRIM(customer_id), '') IS NOT NULL
ORDER BY TRIM(customer_id);

-- stg.geolocation
DROP TABLE IF EXISTS stg.geolocation;
CREATE TABLE stg.geolocation (
	zip_code_prefix	integer,
	lat				numeric(10,6),
	lng				numeric(10,6),
	city			text,
	state			text
);

INSERT INTO stg.geolocation (zip_code_prefix, lat, lng, city, state)
SELECT DISTINCT
	NULLIF(TRIM(geolocation_zip_code_prefix), '')::integer AS zip_code_prefix,
	NULLIF(TRIM(geolocation_lat), '')::numeric AS lat,
	NULLIF(TRIM(geolocation_lng), '')::numeric AS lng,
	NULLIF(TRIM(geolocation_city), '') AS city,
	NULLIF(TRIM(geolocation_state), '') AS STATE
FROM raw.olist_geolocation
WHERE NULLIF(TRIM(geolocation_zip_code_prefix), '') IS NOT NULL;

CREATE INDEX IF NOT EXISTS ix_stg_geolocation_zip ON stg.geolocation(zip_code_prefix);

-- stg.orders
DROP TABLE IF EXISTS stg.orders;
CREATE TABLE stg.orders (
	order_id				text PRIMARY KEY,
	customer_id				text NOT NULL,
	order_status			text NOT NULL,
	order_purchase_ts		timestamp,
	order_approved_ts		timestamp,
	delivered_carrier_ts	timestamp,
	delivered_customer_ts	timestamp,
	estimated_delivery_ts	timestamp
);

INSERT INTO stg.orders (
	order_id, customer_id, order_status, order_purchase_ts, order_approved_ts,
	delivered_carrier_ts, delivered_customer_ts, estimated_delivery_ts
)
SELECT DISTINCT ON (TRIM(order_id))
	TRIM(order_id) AS order_id,
	TRIM(customer_id) AS customer_id,
	LOWER(TRIM(order_status)) AS order_status,
	NULLIF(TRIM(order_purchase_timestamp), '')::timestamp AS order_purcahse_ts,
	NULLIF(TRIM(order_approved_at), '')::timestamp AS order_approved_ts,
	NULLIF(TRIM(order_delivered_carrier_date), '')::timestamp AS delivered_carrier_ts,
	NULLIF(TRIM(order_delivered_customer_date), '')::timestamp AS delivered_customer_ts,
	NULLIF(TRIM(order_estimated_delivery_date), '')::timestamp AS estimated_delivery_ts
FROM raw.olist_orders
WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
	AND NULLIF(TRIM(customer_id), '') IS NOT NULL
ORDER BY TRIM(order_id);

CREATE INDEX IF NOT EXISTS ix_stg_orders_customers ON stg.orders(customer_id);
CREATE INDEX IF NOT EXISTS ix_stg_orders_purchase_ts ON stg.orders(order_purchase_ts);

-- stg.order_items
DROP TABLE IF EXISTS stg.order_items;
CREATE TABLE stg.order_items (
	order_id			text NOT NULL,
	order_item_id		integer NOT NULL,
	product_id			text NOT NULL,
	seller_id			text NOT NULL,
	shipping_limit_ts	timestamp,
	price				numeric(12,2),
	freight_value		numeric(12,2),
	PRIMARY KEY (order_id, order_item_id)
);

INSERT INTO stg.order_items (
	order_id, order_item_id, product_id, seller_id,
	shipping_limit_ts, price, freight_value
)
SELECT DISTINCT ON (TRIM(order_id), NULLIF(TRIM(order_item_id), '')::integer)
	TRIM(order_id) AS order_id,
	NULLIF(TRIM(order_item_id), '')::integer AS order_item_id,
	TRIM(product_id) AS product_id,
	TRIM(seller_id) AS seller_id,
	NULLIF(TRIM(shipping_limit_date), '')::timestamp AS shipping_limit_ts,
	NULLIF(TRIM(price), '')::numeric(12,2) AS price,
	NULLIF(TRIM(freight_value), '')::numeric(12,2) AS freight_value
FROM raw.olist_order_items
WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
  AND NULLIF(TRIM(order_item_id), '') IS NOT NULL
  AND NULLIF(TRIM(product_id), '') IS NOT NULL
  AND NULLIF(TRIM(seller_id), '') IS NOT NULL
ORDER BY TRIM(order_id), NULLIF(TRIM(order_item_id), '')::integer;

CREATE INDEX IF NOT EXISTS ix_stg_items_product ON stg.order_items(product_id);
CREATE INDEX IF NOT EXISTS ix_stg_items_seller ON stg.order_items(seller_id);

-- stg.products
DROP TABLE IF EXISTS stg.products;
CREATE TABLE stg.products (
	product_id					text PRIMARY KEY,
	product_category_name		text,
	product_name_length			integer,
	product_description_length	integer,
	product_photos_qty			integer,
	product_weight_g			integer,
	product_length_cm			integer,
	product_height_cm			integer,
	product_width_cm			integer
);

INSERT INTO stg.products (
	product_id, product_category_name, product_name_length,
	product_description_length, product_photos_qty, product_weight_g,
	product_length_cm, product_height_cm, product_width_cm
)
SELECT DISTINCT ON (TRIM(product_id))
	TRIM(product_id) AS product_id,
	NULLIF(TRIM(product_category_name), '') AS product_category_name,
	NULLIF(TRIM(product_name_lenght), '')::integer AS product_name_length,
	NULLIF(TRIM(product_description_lenght), '')::integer AS product_description_length,
	NULLIF(TRIM(product_photos_qty), '')::integer AS product_photos_qty,
	NULLIF(TRIM(product_weight_g), '')::integer AS product_weight_g,
	NULLIF(TRIM(product_length_cm), '')::integer AS product_length_cm,
	NULLIF(TRIM(product_height_cm), '')::integer AS product_height_cm,
	NULLIF(TRIM(product_width_cm), '')::integer AS product_width_cm
FROM raw.olist_products
WHERE NULLIF(TRIM(product_id), '') IS NOT NULL
ORDER BY TRIM(product_id);

-- stg.sellers
DROP TABLE IF EXISTS stg.sellers;
CREATE TABLE stg.sellers (
	seller_id		text PRIMARY KEY,
	zip_code_prefix	integer,
	city			text,
	state			text
);

INSERT INTO stg.sellers (seller_id, zip_code_prefix, city, state)
SELECT DISTINCT ON (TRIM(seller_id))
	TRIM(seller_id) AS seller_id,
	NULLIF(TRIM(seller_zip_code_prefix), '')::integer AS zip_code_prefix,
	NULLIF(TRIM(seller_city), '') AS city,
	NULLIF(TRIM(seller_state), '') AS state
FROM raw.olist_sellers
WHERE NULLIF(TRIM(seller_id), '') IS NOT NULL
ORDER BY TRIM(seller_id);

-- stg.payments
DROP TABLE IF EXISTS stg.payments;
CREATE TABLE stg.payments (
	order_id				text NOT NULL,
	payment_sequential		integer NOT NULL,
	payment_type			text,
	payment_installments	integer,
	payment_value			numeric(12,2),
	PRIMARY KEY (order_id, payment_sequential)
);

INSERT INTO stg.payments (
	order_id, payment_sequential, payment_type, payment_installments, payment_value
)
SELECT DISTINCT ON (TRIM(order_id), NULLIF(TRIM(payment_sequential), '')::integer)
	TRIM(order_id) AS order_id,
	NULLIF(TRIM(payment_sequential), '')::integer AS payment_sequential,
	NULLIF(LOWER(TRIM(payment_type)), '') AS payment_type,
	NULLIF(TRIM(payment_installments), '')::integer AS payment_installments,
	NULLIF(TRIM(payment_value), '')::numeric(12,2) AS payment_value
FROM raw.olist_order_payments
WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
  AND NULLIF(TRIM(payment_sequential), '') IS NOT NULL
ORDER BY TRIM(order_id), NULLIF(TRIM(payment_sequential), '')::integer;

-- stg.reviews
DROP TABLE IF EXISTS stg.reviews;
CREATE TABLE stg.reviews (
	review_id				text PRIMARY KEY,
	order_id				text NOT NULL,
	review_score			smallint,
	review_comment_title	text,
	review_comment_msg		text,
	review_creation_ts		timestamp,
	review_answer_ts		timestamp
);

INSERT INTO stg.reviews (
	review_id, order_id, review_score, review_comment_title,
	review_comment_msg, review_creation_ts, review_answer_ts
)
SELECT DISTINCT ON (TRIM(review_id))
	TRIM(review_id) AS review_id,
	TRIM(order_id) AS order_id,
	NULLIF(TRIM(review_score), '')::smallint AS review_score,
	NULLIF(TRIM(review_comment_title), '') AS review_comment_title,
	NULLIF(TRIM(review_comment_message), '') AS review_comment_msg,
	NULLIF(TRIM(review_creation_date), '')::timestamp AS review_creation_ts,
	NULLIF(TRIM(review_answer_timestamp), '')::timestamp AS review_answer_ts
FROM raw.olist_order_reviews
WHERE NULLIF(TRIM(review_id), '') IS NOT NULL
  AND NULLIF(TRIM(order_id), '') IS NOT NULL
ORDER BY TRIM(review_id);

CREATE INDEX IF NOT EXISTS ix_stg_reviews_order ON stg.reviews(order_id);

-- stg.category_translation
DROP TABLE IF EXISTS stg.category_translation;
CREATE TABLE stg.category_translation (
	product_category_name			text PRIMARY KEY,
	product_category_name_english	text
);

INSERT INTO stg.category_translation (product_category_name, product_category_name_english)
SELECT DISTINCT ON (TRIM(product_category_name))
	TRIM(product_category_name) AS product_category_name,
	NULLIF(TRIM(product_category_name_english), '') AS product_category_name_english
FROM raw.olist_category_translation
WHERE NULLIF(TRIM(product_category_name), '') IS NOT NULL
ORDER BY TRIM(product_category_name);


-- SANITY CHECKS
SELECT 'customers' tbl, count(*) FROM stg.customers
UNION ALL SELECT 'orders', count(*) FROM stg.orders
UNION ALL SELECT 'order_items', count(*) FROM stg.order_items
UNION ALL SELECT 'products', count(*) FROM stg.products
UNION ALL SELECT 'sellers', count(*) FROM stg.sellers
UNION ALL SELECT 'payments', count(*) FROM stg.payments
UNION ALL SELECT 'reviews', count(*) FROM stg.reviews;

-- CHECK ORPHAN KEYS
SELECT count(*) AS orphan_orders
FROM stg.orders o
LEFT JOIN stg.customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

