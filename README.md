# 🏦 Banking ETL Pipeline — SSIS Project

## 📌 Project Overview
An end-to-end **ETL pipeline** built using **SQL Server Integration Services (SSIS)** that extracts raw banking transaction data, transforms and cleans it, and loads it into a structured **Data Warehouse** for analytical reporting.

---

## 🎯 Business Problem
Financial institutions generate massive volumes of transaction data daily. This project simulates a real-world banking ETL pipeline that consolidates raw transactional data into a clean, optimized Data Warehouse — enabling faster reporting, fraud pattern analysis, and business intelligence.

---

## 🛠️ Tools & Technologies
- **SQL Server Management Studio (SSMS)** — Database design & querying
- **SQL Server Integration Services (SSIS)** — ETL pipeline development
- **T-SQL** — Schema design, constraints, and transformations
- **Star Schema** — Data Warehouse modeling

---

## 🗄️ Data Source
- **Dataset:** Financial Transactions Dataset (Kaggle)
- **Source:** [kaggle.com/datasets/computingvictor/transactions-fraud-datasets](https://www.kaggle.com/datasets/computingvictor/transactions-fraud-datasets)
- **Size:** 1.42 GB | ~2.7 Million transactions
- **Tables:** users_data, cards_data, transactions_data

---

## 🏗️ Project Architecture

```
📦 Source (Banking_OLTP)
    ├── users_data
    ├── cards_data
    └── transactions_data
           │
           ▼
    🔄 SSIS ETL Package
    ├── Data Extraction
    ├── Data Cleaning (NULL handling, duplicates)
    ├── Data Transformation
    │   ├── Lookup (Surrogate Keys)
    │   ├── Derived Column (Date/Time splitting)
    │   ├── Conditional Split (Error flagging)
    │   └── SCD Type 2 (Historical tracking)
           │
           ▼
📊 Destination (Banking_DWH)
    ├── Dim_User      (SCD Type 2)
    ├── Dim_Card      (SCD Type 2)
    ├── Dim_Date
    ├── Dim_Time
    ├── Dim_Merchant
    └── Fact_Transactions
```

---

## 📐 Data Warehouse — Star Schema

```
         Dim_User
             │
Dim_Time ────┼──── Fact_Transactions ────┬──── Dim_Card
             │                           │
         Dim_Date               Dim_Merchant
```

### Dimensions:
| Table | Description | SCD Type |
|-------|-------------|----------|
| Dim_User | Customer demographics & financial profile | Type 2 |
| Dim_Card | Card details & credit information | Type 2 |
| Dim_Date | Full date breakdown (Year, Month, Quarter, etc.) | Static |
| Dim_Time | Time breakdown (Hour, Minute, AM/PM, Period) | Static |
| Dim_Merchant | Merchant location & category | Static |

### Fact Table:
| Table | Grain | Measures |
|-------|-------|---------|
| Fact_Transactions | One row per transaction | Amount, Use_Chip, Errors |

---

## 🔄 SSIS Transformations Used
- **Lookup** — Map source IDs to Surrogate Keys in dimensions
- **Derived Column** — Split datetime into separate Date & Time, flag errors
- **Conditional Split** — Separate NULL errors from valid transactions
- **SCD Component** — Handle Type 2 changes in Dim_User & Dim_Card
- **Data Conversion** — Standardize data types across sources
- **Aggregate** — Summarize transaction totals per merchant/user

---

## 📁 Repository Structure
```
Banking-ETL-SSIS-Project/
├── 1_OLTP/
│   └── OLTP_Schema.sql        # Source database schema & relationships
├── 2_DWH/
│   └── DWH_Schema.sql         # Data Warehouse schema (Star Schema)
├── 3_SSIS/
│   └── Banking_ETL.dtsx       # SSIS Package
└── README.md
```

---

## 🚀 How to Run
1. Restore `Banking_OLTP` database using `OLTP_Schema.sql` in SSMS
2. Create `Banking_DWH` database using `DWH_Schema.sql` in SSMS
3. Open `Banking_ETL.dtsx` in Visual Studio (SSIS)
4. Configure connection managers to point to your SQL Server
5. Run the SSIS package

---

## 💡 Key Learnings
- Designed a normalized **OLTP schema** with proper PKs, FKs, and constraints
- Built a **Star Schema Data Warehouse** optimized for analytical queries
- Implemented **SCD Type 2** to track historical changes in customer & card data
- Developed a full **ETL pipeline** using SSIS with real-world transformations
- Worked with a real **1.42 GB dataset** of banking transactions
