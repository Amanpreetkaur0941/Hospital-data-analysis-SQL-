# 🏥 Hospital Data Analysis — SQL Project

**Author:** Amanpreet Kaur  
**Tools Used:** MySQL  
**Domain:** Healthcare Analytics  
**Type:** Data Cleaning + Exploratory Data Analysis (EDA)



## 📌 Project Overview

This project performs end-to-end data analysis on a hospital database (Novara Hospital) containing patient records, encounters, payers, and medical procedures. The goal was to clean the raw data, validate its integrity, and extract meaningful clinical and business insights across three key objectives — Encounters Overview, Cost & Coverage Insights, and Patient Behaviour Analysis.

---

## 🗂️ Dataset Description

The database (`hospital_db`) consists of four main tables:

| Table | Description |
|---|---|
| `patients` | Patient demographics and personal details |
| `encounters` | Hospital visit records including cost, class, and payer info |
| `payers` | Insurance and payer details |
| `procedures` | Medical procedures performed with associated base costs |

---

##  Data Cleaning Steps

Staging tables were created for all four tables to preserve the original raw data before any modifications.

### 1. Orphan Record Removal
- Identified **16 encounter records** with no matching `patient_id` in the patients table using a LEFT JOIN
- These represented ~0.07% of total data and were safely removed

### 2. Duplicate Detection & Removal
- Used `ROW_NUMBER()` window function partitioned by key columns (Patient, Start, Stop, EncounterClass, Payer)
- Found and removed **16 duplicate rows** — total reduced from **27,872 → 27,856** clean records
- No duplicates were found in `procedures` or `payers` tables

### 3. Data Validation Checks

| Check | Result |
|---|---|
| NULL values in critical fields |  None found |
| Logical validity (Start > Stop) |  No invalid records |
| Negative cost values |  No anomalies found |

---

##  Analysis & Key Findings

### 🔹 Objective 1: Encounters Overview

**Encounter Class Distribution**
- Ambulatory encounters are the most frequent at **~42%** of all encounters
- Outpatient encounters account for **~20%**
- Trend was stable from 2011–2020, with a notable shift in 2021 where outpatient surpassed ambulatory

| Encounter Class | Count |
|---|---|
| Ambulatory | 12,529 |
| Outpatient | 6,287 |
| Urgent Care | 3,664 |
| Emergency | 2,321 |
| Wellness | 1,920 |
| Inpatient | 1,135 |

**Stay Duration Analysis**
- **~96%** of encounters (26,704) were completed within 24 hours
- Only **~4%** (1,152) were over 24 hours

>  *This indicates the hospital primarily focuses on short-term, non-critical care services with high patient throughput.*

---

### 🔹 Objective 2: Cost & Coverage Insights

**Zero Payer Coverage**
- **~49%** of encounters (13,577 out of 27,856) had **zero payer coverage**
- Nearly half of all visits were not supported by any insurance

>  *This signals a significant gap in insurance penetration and potential revenue leakage for the hospital.*

**Top Procedures by Volume**
- Preventive and assessment procedures dominate volume
- *"Assessment of health and social care needs"* is the most frequently performed procedure
- High-volume procedures tend to have relatively **lower average costs**, indicating operational efficiency in routine services

**Most Expensive Procedures**

| Procedure | Count | Avg Base Cost |
|---|---|---|
| Admit to ICU | 5 | $206,260 |
| Coronary artery bypass grafting | 9 | $47,086 |
| Lumpectomy of breast | 5 | $29,353 |
| Hemodialysis | 27 | $29,300 |
| Electrical cardioversion | 1,383 | $25,903 |

>  *ICU admissions are rare but extremely resource-intensive. Electrical cardioversion is unique — it is both high-volume AND high-cost, making it a key area for efficiency optimization.*

**Average Claim Cost by Payer**

| Payer | Avg Claim Cost |
|---|---|
| Medicaid | $6,205 |
| No Insurance | $5,597 |
| Anthem | $4,237 |
| Humana | $3,269 |
| Medicare | $2,168 |
| Dual Eligible | $1,696 |

>  *Medicaid and uninsured patients have the highest average claim costs, likely due to delayed treatment and higher clinical complexity. Medicare and private insurers show lower costs, reflecting structured treatment pathways.*

---

### 🔹 Objective 3: Patient Behaviour Analysis

**Quarterly Admissions Trend**
- Patient admissions show a **generally stable trend** across quarters — no strong seasonal spikes
- Peak admissions occurred in **Q1 of 2014 and Q1 of 2021**

**30-Day Readmission Analysis**
- **17,308 total readmission events** were identified within 30 days of a previous encounter
- Repeated readmissions were concentrated among a small group of patients, indicating a pattern beyond random occurrences
- The top readmitted patient had **1,376 readmissions**, signalling chronic or high-risk cases

---

##  Key Insights Summary

| Theme | Finding |
|---|---|
| Encounter type | Ambulatory & outpatient dominate (~62% combined) |
| Stay duration | 96% of visits are under 24 hours |
| Insurance gap | ~49% of encounters have zero payer coverage |
| Procedure volume | Preventive care (assessment procedures) dominates |
| Procedure cost | Critical care (ICU) dominates cost at $206K avg |
| Readmissions | 17,308 cases — concentrated in a few high-risk patients |

---

##  SQL Concepts Used

| Concept | Usage |
|---|---|
| `CREATE TABLE ... LIKE` | Staging table creation |
| `LEFT JOIN` | Orphan record detection |
| `ROW_NUMBER() OVER (PARTITION BY)` | Duplicate detection and removal |
| `GROUP BY` + Aggregates | Encounter counts, cost averages |
| `SUM() OVER (PARTITION BY)` | Year-wise percentage contribution |
| `LAG()` | 30-day readmission detection |
| `TIMESTAMPDIFF()` | Duration and readmission gap calculation |
| `CASE` | Stay duration categorization |
| `CTEs` | Multi-step readmission logic |
| Subqueries | Percentage of total calculations |

---

## 📁 Project Structure

```
hospital-data-analysis/
│
├── Hospital_analysis_.sql        Main SQL file (data cleaning + EDA)
├── Novara_Hospital.pdf            Presentation with insights & recommendations
└── Screenshots                    SQL Output
└── README.md                      Project documentation
```

---

##  How to Run

1. Import the `hospital_db` database into your MySQL environment
2. Run `Hospital_analysis_2.sql` sequentially from top to bottom
3. Staging tables will be created automatically
4. All analysis queries are clearly sectioned with comments

---

##  Recommendations Summary

**Encounters & Operations**
- Prioritize staffing and infrastructure for ambulatory and outpatient services
- Improve patient throughput efficiency given the high volume of short-duration encounters

**Cost & Coverage**
- Strengthen insurance partnerships and improve verification at admission
- Design financial assistance programs for uninsured and underinsured patient segments
- Monitor high-cost procedures (especially ICU admissions and electrical cardioversion)

**Patient Behaviour**
- Build a high-risk patient tracking system to flag frequent readmitters
- Strengthen post-discharge follow-up programs
- Introduce chronic disease management and preventive care plans

---

##  About the Author

**Amanpreet Kaur** — Aspiring Data Analyst with skills in SQL, Excel, and data storytelling.  
Currently building a portfolio in business analytics.

  Let's Connect on [LinkedIn](https://www.linkedin.com/in/amanpreet-kaur-37aa17242/) 
  [GitHub](https://github.com/Amanpreetkaur0941)

---

*This project was completed as part of a self-learning journey in data analytics using the Practice Hospital dataset from  [Maven Analytics](https://mavenanalytics.io/data-playground).*
