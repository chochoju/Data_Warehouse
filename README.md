# Data Warehouse & BI Case Study (Star Schema w/ PostgreSQL + Power BI)



## Project Overview



This project is a **case study designed to understand how data flows, transforms, and is consumed in real-world corporate data operations**, using a public e-commerce dataset.



It simulates a **production-style analytics pipeline** — from raw transactional data to staging, data warehouse (star schema), analytical data marts, and finally a **Power BI dashboard** for business users.



The goal is **not only visualization**, but to demonstrate:



- how structured data is modeled for analytics,

- how intermediate transformation layers support data quality and reuse,

- and how BI tools consume curated data marts instead of raw tables.



The dataset used is the **Olist Brazilian E-commerce dataset**, a widely used public dataset that closely resembles real operational e-commerce data.



---



## Why this project?



In many corporations:



- raw data comes from multiple operational systems,

- transformations are layered (raw → staging → warehouse → marts),

- dashboards are built on curated, stable views rather than raw tables.



This project mirrors that reality and serves as a **hands-on case study** for:



- understanding data operations in retail / e-commerce companies,

- practicing analytics-oriented data modeling,

- and bridging the gap between data engineering concepts and business analytics.



---



## Architecture Overview



```

Raw CSV Files

   ↓

RAWSchema (PostgreSQL)

   ↓

STGSchema (cleaning, typing, deduplication)

   ↓

DWSchema (starschema: dimensions & facts)

   ↓

MARTSchema (business-focused views)

   ↓

Power BI Dashboard



```



### Schema layers



- **RAW**: Landing tables mirroring source CSVs (minimal transformation)

- **STG**: Cleaned and standardized tables (data types, keys, basic validation)

- **DW**: Star schema with dimensions and fact tables

- **MART**: Business-ready aggregated views used directly by Power BI



---



## Tech Stack



- **Database**: PostgreSQL

- **Modeling**: Star schema (facts & dimensions)

- **Transformation**: SQL (PostgreSQL)

- **Visualization**: Power BI

- **Data Source**: Public Olist e-commerce dataset



---



## Power BI Dashboard



The Power BI report is built **entirely on top of `mart.*` views**, reflecting best practices in analytics organizations where BI tools do not directly query raw or transactional tables.



### Dashboard pages (max 3 pages)



1. **Executive Overview**

   - GMV & order trends

   - Category performance

   - Geographic GMV by customer state (map)

2. **Delivery & Customer Experience**

   - On-time delivery rate

   - Delivery time trends

   - Seller performance vs customer reviews

3. **Growth & Monetization Drivers**

   - Customer segmentation (New / Returning / Loyal)

   - Payment mix trends

   - Seller concentration & revenue drivers



Each page is designed to answer a specific business question while maintaining a clean, corporate reporting style.



---



## Repository Structure



```

┌─ sql/

│  ├─00_init.sql-- schema creation

│  ├─10_raw.sql-- raw table definitions

│  ├─20_stg.sql-- staging transformations

│  ├─30_dw.sql-- data warehouse (star schema)

│  └─40_marts.sql-- BI-ready data marts

├─ docs/

│  ├─ architecture.md

│  └─ erd.png

├─ powerbi/

│  ├─ecommerce_analysis.pbix-- Power BI Dashboard

│  └─ecommerce_analysis_screenshot.pdf-- Dashboard screenshots

├─ data/

  └─ README.md-- dataset download instructions

└─ README.md

```



---



## Key Business Questions Answered



- How is GMV and order volume trending over time?

- Which product categories and regions drive revenue?

- How reliable is delivery performance?

- What proportion of customers are repeat buyers?

- How diversified are payment methods?

- Is revenue concentrated among a small number of sellers?



---



## Dataset Information



This project uses the **Olist Brazilian E-commerce Public Dataset**, available on Kaggle:



🔗 **Dataset Link**



https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce



**Dataset characteristics**



- Multiple relational tables (orders, customers, items, payments, reviews, sellers)

- Realistic data issues (nulls, multiple grains, timestamps, categorical fields)

- Suitable for simulating real e-commerce analytics workflows



---



## How to Run the Project



1. Create schemas using `sql/00_init.sql`

2. Create raw tables using `sql/10_raw.sql`

3. Load CSV files into `raw.*` tables (pgAdmin Import Tool recommended on Windows)

4. Run `sql/20_stg.sql` to build staging tables

5. Run `sql/30_dw.sql` to build the data warehouse

6. Run `sql/40_marts.sql` to create analytical marts

7. Connect Power BI to PostgreSQL and load `mart.*` views



---



## Notes



Due to local file permission restrictions in PostgreSQL on Windows, CSV files were loaded using **pgAdmin’s Import/Export tool**.



`COPY` command templates are included in SQL files for reference and portability.



---



## Contact



If you’d like to discuss this project or my work:



- **LinkedIn:** https://www.linkedin.com/in/juyeon-cho/

- **Email:** jc973@alumni.duke.edu

