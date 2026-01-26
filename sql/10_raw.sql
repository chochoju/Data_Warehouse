-- RAW LAYER

DROP TABLE IF EXISTS raw.olist_customers;
CREATE TABLE raw.olist_customers (
	customer_id					text,
	customer_unique_id			text,
	customer_zip_code_prefix	text,
	customer_city				text,
	customer_state				text
);

DROP TABLE IF EXISTS raw.olist_geolocation;
CREATE TABLE raw.olist_geolocation (
	geolocation_zip_code_prefix	text,
	geolocation_lat				text,
	geolocation_lng				text,
	geolocation_city			text,
	geolocation_state			text
);

DROP TABLE IF EXISTS raw.olist_orders;
CREATE TABLE raw.olist_orders (
	order_id						text,
	customer_id						text,
	order_status					text,
	order_purchase_timestamp		text,
	order_approved_at				text,
	order_delivered_carrier_date	text,
	order_delivered_customer_date	text,
	order_estimated_delivery_date	text
);

DROP TABLE IF EXISTS raw.olist_order_items;
CREATE TABLE raw.olist_order_items (
	order_id				text,
	order_item_id			text,
	product_id				text,
	seller_id				text,
	shippipng_limit_date	text,
	price					text,
	freight_value			text
);

DROP TABLE IF EXISTS raw.olist_products;
CREATE TABLE raw.olist_products (
	product_id					text,
	product_category_name		text,
	product_name_lenght			text,
	product_description_lenght	text,
	product_photos_qty			text,
	product_weight_g			text,
	product_length_cm			text,
	product_height_cm			text,
	product_width_cm			text
);

DROP TABLE IF EXISTS raw.olist_sellers;
CREATE TABLE raw.olist_sellers (
	seller_id				text,
	seller_zip_code_prefix	text,
	seller_city				text,
	seller_state			text
);

DROP TABLE IF EXISTS raw.olist_order_payments;
CREATE TABLE raw.olist_order_payments (
	order_id				text,
	payment_sequential		text,
	payment_type			text,
	payment_installments	text,
	payent_value			text
);

DROP TABLE IF EXISTS raw.olist_order_reviews;
CREATE TABLE raw.olist_order_reviews (
	review_id				text,
	order_id				text,
	review_score			text,
	review_comment_title	text,
	review_comment_message	text,
	review_creation_date	text,
	review_answer_timestamp	text
);

DROP TABLE IF EXISTS raw.olist_category_translation;
CREATE TABLE raw.olist_category_translation (
	product_category_name			text,
	product_category_name_english	text
);


-- LOAD RAW

COPY raw.olist_customers FROM "C:\Users\Qcells\Desktop\Github\Data_Warehouse\data\raw\olist_customers.csv" WITH (FORMAT csv, HEADER true); 
COPY raw.olist_geolocation FROM "C:\Users\Qcells\Desktop\Github\Data_Warehouse\data\raw\olist_geolocation.csv" WITH (FORMAT csv, HEADER true);
COPY raw.olist_orders FROM "C:\Users\Qcells\Desktop\Github\Data_Warehouse\data\raw\olist_orders.csv" WITH (FORMAT csv, HEADER true);
COPY raw.olist_order_items FROM "C:\Users\Qcells\Desktop\Github\Data_Warehouse\data\raw\olist_order_items.csv" WITH (FORMAT csv, HEADER true);
COPY raw.olist_products FROM "C:\Users\Qcells\Desktop\Github\Data_Warehouse\data\raw\olist_products.csv" WITH (FORMAT csv, HEADER true);
COPY raw.olist_sellers FROM "C:\Users\Qcells\Desktop\Github\Data_Warehouse\data\raw\olist_sellers.csv" WITH (FORMAT csv, HEADER true);
COPY raw.olist_order_payments FROM "C:\Users\Qcells\Desktop\Github\Data_Warehouse\data\raw\olist_order_payments.csv" WITH (FORMAT csv, HEADER true);
COPY raw.olist_order_reviews FROM "C:\Users\Qcells\Desktop\Github\Data_Warehouse\data\raw\olist_order_reviews.csv" WITH (FORMAT csv, HEADER true);
COPY raw.olist_category_translation FROM "C:\Users\Qcells\Desktop\Github\Data_Warehouse\data\raw\olist_product_category_translation.csv" WITH (FORMAT csv, HEADER true);


