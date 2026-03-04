# Data Warehouse Architecture

This project implements a simplified analytics architecture that mirrors the
data workflow commonly used in real organizations.

The goal is to simulate how raw operational data flows through multiple layers
before becoming business-ready datasets used by analytics teams and BI tools.

---

## Architecture Overview

Raw CSV Files
      │
      ▼
RAW Schema (PostgreSQL)
      │
      ▼
STG Schema (Data Cleaning & Standardization)
      │
      ▼
DW Schema (Star Schema Data Warehouse)
      │
      ▼
MART Schema (Business Aggregations)
      │
      ▼
Power BI Dashboard

---

## Layer Descriptions

### 1. RAW Layer
The raw layer stores the original CSV datasets with minimal transformation.

Purpose:
- Preserve original source data
- Enable reproducibility
- Provide a historical reference

Tables mirror the original Olist dataset structure.

Example tables:

- olist_orders
- olist_customers
- olist_products
- olist_order_items
- olist_order_payments
- olist_order_reviews
- olist_sellers
- olist_geolocation
- product_category_name_translation

---

### 2. STG Layer (Staging)

The staging layer prepares data for analytics by applying:

- Data type corrections
- Null handling
- Deduplication
- Standardized naming
- Basic integrity validation

This layer acts as a **clean interface between raw data and analytics models**.

---

### 3. DW Layer (Data Warehouse)

The warehouse layer follows a **star schema design** to optimize analytical queries.

Dimensions:

- dim_customer
- dim_product
- dim_seller
- dim_payment_type

Fact Tables:

- fact_order
- fact_order_item
- fact_payment
- fact_review

Benefits:

- Simplified joins
- Consistent keys
- Scalable analytical structure

---

### 4. MART Layer

Data marts contain **business-ready views and aggregations** used directly by
Power BI dashboards.

Example marts:

- mart.daily_gmv
- mart.category_sales
- mart.delivery_sla
- mart.customer_segments_monthly
- mart.payment_mix_daily
- mart.seller_performance_monthly
- mart.gmv_by_customer_state
- mart.sellers_by_state

These views abstract complexity from BI tools and ensure consistent metrics.

---

### 5. BI Layer (Power BI)

Power BI connects directly to the `mart` schema.

Dashboards are built using curated views instead of raw transactional tables.

Benefits:

- faster queries
- consistent KPIs
- simpler data model
- easier maintenance

---

## Key Design Principles

1. Layered architecture
2. Separation of raw and analytical data
3. Star schema modeling
4. BI tools query curated views instead of raw tables
5. Reproducible SQL pipeline

---

## Purpose of This Case Study

This project was built as a learning exercise to understand how
corporate data systems are structured.

It demonstrates the typical pipeline used by analytics teams:

data ingestion → transformation → warehouse modeling → BI reporting