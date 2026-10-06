# Databricks dbt Medallion Architecture (`dish_dbt`)

A comprehensive **dbt (Data Build Tool)** project implementing a **Medallion Architecture (Bronze → Silver → Gold)** on **Databricks**. This project handles end-to-end data ingestion, transformation, deduplication, testing, and snapshotting (SCD Type-2).

---

## 🏗️ Architecture Overview

The pipeline follows standard data lakehouse design patterns, transforming raw operational sources into clean, aggregated business datasets across three schemas:

```
                  ┌──────────────────────┐
                  │    Raw Source Data   │
                  │ (dbt_catalog.source) │
                  └──────────┬───────────┘
                             │
                             ▼
 ┌───────────────────────────────────────────────────────┐
 │                   BRONZE LAYER                        │
 │  In-schema tables/views: Raw ingestion & mapping       │
 └───────────────────────────┬───────────────────────────┘
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
 ┌─────────────────────┐           ┌────────────────────┐
 │    SILVER LAYER     │           │     GOLD LAYER     │
 │ Aggregations & Joins│           │ Deduplicated & SCD2│
 └─────────────────────┘           └────────────────────┘
```

---

## 📁 Project Structure & Components

```
dish_dbt/
├── analyses/                  # SQL scripts and Jinja templates for data analysis
│   ├── 1.sql
│   ├── jinja1.sql, jinja2.sql, jinja3.sql
│   └── query_macro.sql
├── macros/                    # Reusable Jinja macros
│   ├── generate_schema.sql    # Custom schema naming override
│   └── multiply.sql           # Multiplication utility macro
├── models/
│   ├── source/
│   │   └── sources.yml        # Source declarations (dim_customer, fact_sales, items, etc.)
│   ├── bronze/                # Raw ingestion models (materialized: table/view)
│   │   ├── bronze_customers.sql
│   │   ├── bronze_date.sql
│   │   ├── bronze_product.sql
│   │   ├── bronze_returns.sql
│   │   ├── bronze_sales.sql
│   │   ├── bronze_store.sql
│   │   └── properties.yml     # Schema documentation & data quality tests
│   ├── silver/                # Cleaned, enriched, and aggregated models
│   │   └── silver_sales_info.sql
│   └── gold/                  # Production-ready analytical views
│       └── source_gold_items.sql
├── seeds/                     # Static lookup datasets
│   └── lookup.csv
├── snapshots/                 # SCD Type-2 dimension snapshots
│   └── gold_items.yml
├── tests/                     # Custom data quality tests
│   ├── non_negative_test.sql  # Singular test verifying non-negative sales amounts
│   └── generic/
│       └── generic_non_negatve.sql # Custom reusable generic test macro
├── dbt_project.yml            # Core dbt project configuration
└── profiles.yml               # Connection profile for Databricks
```

---

## 📊 Model Layer Details

### 1. Bronze Layer (`models/bronze/`)
* **Materialization:** `table` / `view` (Schema: `bronze`)
* Ingests raw dimensional and fact data directly from `dbt_catalog.source`:
  * `bronze_customers`: Customer master data (`dim_customer`)
  * `bronze_date`: Calendar lookup table (`dim_date`)
  * `bronze_product`: Product catalog (`dim_product`)
  * `bronze_returns`: Return transaction log (`fact_returns`)
  * `bronze_sales`: Sales transaction records (`fact_sales`)
  * `bronze_store`: Store locations (`dim_store`)

### 2. Silver Layer (`models/silver/`)
* **Materialization:** `table` (Schema: `silver`)
* **`silver_sales_info`**: Enriches sales transaction data by joining `bronze_sales`, `bronze_product`, and `bronze_customers`. Uses the `multiply` macro to calculate gross amounts and aggregates total sales performance by product category and customer gender.

### 3. Gold Layer (`models/gold/`)
* **Materialization:** `view` (Schema: `gold`)
* **`source_gold_items`**: Deduplicates raw item records using window functions (`ROW_NUMBER() OVER (PARTITION BY id ORDER BY updateDate DESC)`) to serve the latest version of each entity.

### 4. Snapshots (`snapshots/`)
* **`gold_items`**: Configured for SCD Type-2 tracking on `source.items` based on update timestamps (`updated_at: updateDate`).

---

## 🧪 Data Testing & Quality Control (17 Total Nodes)

The project includes **7 data quality tests** to guarantee data integrity across the pipeline:

1. **`unique`**: Validates unique primary key `sales_id` on `bronze_sales`.
2. **`not_null`**: Ensures `sales_id` on `bronze_sales` is never null.
3. **`not_null`**: Ensures `customer_sk` on `bronze_customers` is never null.
4. **`accepted_values`**: Restricts `store_name` on `bronze_store` to valid store locations.
5. **`accepted_values`**: Restricts `country` on `bronze_store` to `USA` or `Canada`.
6. **`generic_non_negative`**: Custom generic test verifying `gross_amount` on `bronze_sales` is $\ge 0$.
7. **`non_negative_test`**: Singular test checking for negative values in `bronze_sales`.

---

## 🚀 Getting Started & Execution

### Prerequisites
* Python 3.8+
* `dbt-databricks` adapter (`pip install dbt-databricks`)

### Running the Project

1. **Verify Connection:**
   ```bash
   dbt debug
   ```

2. **Seed Static Datasets:**
   ```bash
   dbt seed
   ```

3. **Run Transformations (Models & Snapshots):**
   ```bash
   dbt run
   dbt snapshot
   ```

4. **Execute Data Quality Tests:**
   ```bash
   dbt test
   ```

5. **Run Everything & Validate DAG (17 Nodes):**
   ```bash
   dbt build
   ```
