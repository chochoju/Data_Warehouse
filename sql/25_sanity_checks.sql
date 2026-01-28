-- Sanity Checks

-- Row count comparison (raw->stg)
SELECT 'raw_orders' AS table_name, COUNT(*) FROM raw.olist_orders
UNION ALL
SELECT 'stg_orders', COUNT(*) FROM stg.orders
UNION ALL
SELECT 'raw_customers', COUNT(*) FROM raw.olist_customers
UNION ALL
SELECT 'stg_customers', COUNT(*) FROM stg.customers
UNION ALL
SELECT 'raw_items', COUNT(*) FROM raw.olist_order_items
UNION ALL
SELECT 'stg_items', COUNT(*) FROM stg.order_items;


-- Primary Key Uniqueness (should be zero)
-- Orders
SELECT COUNT(*) AS duplicate_orders
FROM (
  SELECT order_id
  FROM stg.orders
  GROUP BY order_id
  HAVING COUNT(*) > 1
) d;

-- Customers
SELECT COUNT(*) AS duplicate_customers
FROM (
  SELECT customer_id
  FROM stg.customers
  GROUP BY customer_id
  HAVING COUNT(*) > 1
) d;

-- Products
SELECT COUNT(*) AS duplicate_products
FROM (
  SELECT product_id
  FROM stg.products
  GROUP BY product_id
  HAVING COUNT(*) > 1
) d;


-- Orphan Key Checks
-- Orders without customers
SELECT COUNT(*) AS orders_missing_customer
FROM stg.orders o
LEFT JOIN stg.customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

-- Items without orders
SELECT COUNT(*) AS items_missing_order
FROM stg.order_items i
LEFT JOIN stg.orders o ON o.order_id = i.order_id
WHERE o.order_id IS NULL;

-- Items without products
SELECT COUNT(*) AS items_missing_product
FROM stg.order_items i
LEFT JOIN stg.products p ON p.product_id = i.product_id
WHERE p.product_id IS NULL;


-- Numeric Validation
-- Negative prices (should be zero)
SELECT COUNT(*) AS negative_prices
FROM stg.order_items
WHERE price < 0;

-- Negative freight values
SELECT COUNT(*) AS negative_freight
FROM stg.order_items
WHERE freight_value < 0;


-- Date Sanity
-- Delivered before purchase (should be zero)
SELECT COUNT(*) AS bad_delivery_dates
FROM stg.orders
WHERE delivered_customer_ts < order_purchase_ts;

