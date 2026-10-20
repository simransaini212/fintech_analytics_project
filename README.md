# 🚀 Fintech User Onboarding Funnel & Conversion Latency Pipeline

An end-to-end analytical data engineering pipeline analyzing onboarding drop-offs, identity verification (KYC), and first deposit latency across 1,000 users over a 218-day transactional dataset.

---

## 📌 Business Problem & Motivation
In digital retail fintech products, customer acquisition cost (CAC) is high, but revenue realization is delayed because users stall before depositing capital. 

This project solves two primary business objectives:
1. **Quantify Conversion Latency:** Measure the exact drop-off and time elapsed between user registration, KYC submission, and the first capital deposit.
2. **Capital Segmentation (Whale Analysis):** Segment users by deposit volume to uncover revenue concentration and enable targeted CRM retention workflows.

---

## 🏗️ Architecture & Medallion Pipeline
The project implements a modern Lakehouse / Medallion Architecture:

- **Bronze Layer (Raw Ingestion):** Ingests raw event streams (`events_raw.csv`) tracking user onboarding steps (`Signup`, `KYC_Submitted`, `KYC_Approved`, `First_Deposit`).
- **Silver Layer (Validation & Fact Store):** Python ETL pipeline cleanses dirty records, generates surrogate sequential keys, handles null values, and bulk loads data into SQL Server (`dbo.fct_events`).
- **Gold Layer (Analytical Marts):** Automated Stored Procedure (`dbo.sp_populate_gold_segments`) materializes user quartile tiers (`dbo.gold_user_segments`) for sub-second executive reporting.

---

## 📊 Key Analytical Findings & Metrics

| Metric | Measured Value | Business Interpretation |
| :--- | :--- | :--- |
| **Total Onboarded Users** | 1,000 | Complete cohort tracked over 218 days |
| **Converted Depositors** | 422 (42.2%) | Users who completed bank setup & funded account |
| **Fastest Conversion** | 32.0 Hours (~1.3 Days) | High-intent power users |
| **Average Conversion Latency** | **132.0 Hours (~5.5 Days)** | Major friction window post-KYC verification |
| **Slowest Conversion** | 238.0 Hours (~10 Days) | Users needing multiple days of consideration |

### 🔍 Funnel Drop-off Cohorts
- **Never Deposited (Churned):** 578 users (57.8%) abandoned the platform after registration.
- **Deposited After 5 Days (Slow):** 235 users (55.7% of converted base) converted late, making **Day 2 to Day 5** the prime friction window for marketing nudges.
- **Converted Within 5 Days (Fast):** 187 users (44.3% of converted base).

### 💰 Deposit Value Segmentation (`NTILE(4)`)
- **Total First-Deposit Revenue:** ₹55,16,318.81
- **Top 50% Users (Quartiles 1 & 2):** Contributed **73.3%** of total capital (~₹40.46 Lakhs).
- **Quartile 1 (Whales):** Average deposit of ₹21,860.88 (42.0% share).
- **Quartile 4 (Micro-Depositors):** Average deposit of ₹3,741.47 (7.1% share) despite taking 25% of operational volume.

---

## 🛠️ Tech Stack
- **Database Engine:** Microsoft SQL Server (T-SQL), SSMS
- **Analytical SQL:** Common Table Expressions (CTEs), Conditional Aggregations, Window Functions (`NTILE`, `SUM() OVER()`, `DATEDIFF`)
- **Pipeline Orchestration:** Python 3 (`pandas`, `pyodbc`), Automated Stored Procedures
- **Data Quality & Resilience:** Idempotent truncate-and-load logic, primary key collision handling
- **Cloud Architecture Design:** Azure Data Factory (ADF), Azure Data Lake Storage Gen2 (ADLS Gen2)
- **Business Intelligence:** Microsoft Power BI (Executive KPIs, Donut Quartiles, Cohort Slicers)

---

## 📂 Repository Contents
- `pipeline_ingest.py`: Automated Python script for data validation, bulk loading, and gold procedure trigger.
- `01_analysis_and_views.sql`: Exploratory queries, funnel latency calculations, and customer segmentation views.
- `02_sp_populate_gold_segments.sql`: Production DDL script for materialized gold reporting table and stored procedure.
- `events_raw.csv`: Sample event stream dataset.
