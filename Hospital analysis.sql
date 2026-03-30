-- ============================================
-- HOSPITAL DATA ANALYSIS PROJECT
-- Author: Amanpreet Kaur
-- Description: Data Cleaning & Exploration using SQL
-- ============================================

-- ============================================
-- DATA CLEANING SUMMARY
-- ============================================
-- 1. Removed ~0.07% orphan encounter records (no matching patient_id)
-- 2. Created staging tables for clean analysis

-- Creating Staging tables

USE hospital_db;

CREATE TABLE encounters_staging
LIKE encounters;
INSERT INTO encounters_staging
SELECT * FROM encounters;

CREATE TABLE patients_staging
LIKE patients;

INSERT INTO patients_staging
SELECT * FROM patients;

CREATE TABLE payers_staging
LIKE payers;

INSERT INTO payers_staging
SELECT * FROM payers;

CREATE TABLE procedures_staging
LIKE procedures;

INSERT INTO procedures_staging
SELECT * FROM procedures;


-- Data Validation
-- Checking orphan records
SELECT *
FROM(
SELECT e.patient,p.id
FROM encounters e
LEFT JOIN patients p 
ON e.patient= p.id) temp;              -- orphan records with no matching patient id in patient tables

-- Count orphan records

SELECT COUNT(*)
FROM(
SELECT e.patient,p.id
FROM encounters e
LEFT JOIN patients p 
ON e.patient= p.id
WHERE e.patient = '204f8028-72f8-d6f8-761f-79ebf9f02311') temp;       -- 19 records found

-- Deleting the orphan records as it is ~ 0.07% of total records

SELECT COUNT(*) FROM encounters_staging
WHERE patient = '204f8028-72f8-d6f8-761f-79ebf9f02311';

DELETE FROM encounters_staging 
WHERE patient = '204f8028-72f8-d6f8-761f-79ebf9f02311';

-- Finding duplicates                                                        

SELECT 
    Patient, 
    Start,
    stop,
    EncounterClass, 
    payer,
    COUNT(*) as duplicate_count
FROM encounters_final
GROUP BY Patient, Start,stop, EncounterClass,payer
HAVING COUNT(*) > 1;

WITH duplicate_cte AS 
( 
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY Patient, 
    Start,
    stop,
    EncounterClass, 
    payer) AS rn
FROM encounters_staging2
)
SELECT COUNT(*) FROM duplicate_cte
WHERE rn>1;



-- Dummy table is  created to delete duplicate values
CREATE TABLE `encounters_staging2` (
  `Id` char(36) NOT NULL,
  `START` datetime NOT NULL,
  `STOP` datetime NOT NULL,
  `PATIENT` char(36) NOT NULL,
  `ORGANIZATION` char(36) NOT NULL,
  `PAYER` char(36) NOT NULL,
  `ENCOUNTERCLASS` varchar(50) DEFAULT NULL,
  `CODE` varchar(20) DEFAULT NULL,
  `DESCRIPTION` varchar(255) DEFAULT NULL,
  `BASE_ENCOUNTER_COST` decimal(10,2) DEFAULT NULL,
  `TOTAL_CLAIM_COST` decimal(10,2) DEFAULT NULL,
  `PAYER_COVERAGE` decimal(10,2) DEFAULT NULL,
  `REASONCODE` varchar(20) DEFAULT NULL,
  `REASONDESCRIPTION` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  `row_num` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DELETE FROM encounters_staging2
WHERE row_num>1;

INSERT INTO encounters_staging2
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY Patient, 
    Start,
    stop,
    EncounterClass, 
    payer) AS rn
FROM encounters_staging;               /* Here duplicates are removed*/

SELECT * FROM patients_staging;



SELECT * FROM procedures_staging;

WITH duplicate_cte AS 
( 
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY Patient,
    Start,
    stop,
    Encounter, 
    description,
    base_cost) AS rn
FROM procedures_staging
)
SELECT COUNT(*) FROM duplicate_cte
WHERE rn>1;                      /* No duplicates found */

-- Finding duplicates in payers staging

WITH duplicate_cte AS 
( 
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY 
    name,
    address, 
    city,
    state_headquartered,
    zip,
    phone) AS rn
FROM payers_staging
)
SELECT COUNT(*) FROM duplicate_cte
WHERE rn>1;                             /* No duplicates found */

-- ============================================
-- DATA VALIDATION CHECK
-- ============================================
USE hospital_db;
-- Before vs After cleaning
SELECT * FROM encounters;         -- rows 27872
SELECT COUNT(*) FROM encounters_staging2;       -- 27856 rows 16 rows were removed as duplicate values

-- NULL check sanity

SELECT *  FROM encounters_staging2
WHERE patient IS NULL;

-- logical Validity

SELECT * FROM encounters_staging2 
WHERE start>stop;

-- Cost sanity check

SELECT * FROM encounters_staging2
WHERE total_claim_cost< 0
 OR base_encounter_cost <0;
 
-- ============================================
-- DATA VALIDATION COMPLETED
-- Dataset is cleaned and ready for analysis
-- ============================================

-- ============================================
-- OBJECTIVES 1.ENCOUNTERS OVERVIEW
--            2.COST & COVERAGE INSIGHTS
--            3.PATIENT BEHAVIOR ANALYSIS
-- ============================================

-- Overview metrics
-- Total encounters
SELECT COUNT(*) FROM encounters_staging2;
SELECT COUNT(*) AS cnt, encounterclass FROM encounters_staging2
GROUP BY encounterclass
ORDER BY COUNT(*) DESC;
-- Total patients
SELECT COUNT(DISTINCT(patient)) FROM encounters_staging2;

-- Q1: How many total encounters occurred each year?

SELECT YEAR(`start`) AS yr, COUNT(id) as total_enct
FROM encounters_staging2
GROUP BY yr
ORDER BY total_enct DESC;

-- For each year, what percentage of all encounters belonged to each encounter class
-- (ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)?

SELECT YEAR(`start`) AS yr,                  /* nesting aggregate functions within window func to find count of id each yeat */
	   encounterclass, 
       COUNT(id) AS total,
       COUNT(id)*100/SUM(COUNT(ID)) OVER(PARTITION BY YEAR(`start`)) AS pct_contribution  /*Year wise total encounters found*/
       FROM encounters_staging2
       GROUP BY yr, encounterclass
       ORDER BY yr, pct_contribution DESC;
       
-- What percentage of encounters were over 24 hours versus under 24 hours?

SELECT                                       /* Using case to find each column */
CASE 
     WHEN TIMESTAMPDIFF(hour,`start`,`stop`)<24 THEN 'Under 24 hrs' 
     ELSE 'OVER 24 hrs'
     END AS stay_category,
     COUNT(id) AS total_encounters,
     COUNT(id)*100/ (SELECT COUNT(*) FROM encounters_staging2) AS pct_enct
FROM encounters_staging2
GROUP BY stay_category;

-- OBJECTIVE 2: COST & COVERAGE INSIGHTS

-- Q1: How many encounters had zero payer coverage, and what percentage of total encounters does this represent?
SELECT COUNT(*) AS total, COUNT(*)*100/(SELECT COUNT(*) FROM encounters_staging2) AS total_pct
FROM encounters_staging2
WHERE payer_coverage = 0;

-- What are the top 10 most frequent procedures performed and the average base cost for each?

SELECT `description`, COUNT(*) AS cnt, AVG(base_cost) AS avg_b_cost
FROM procedures_staging
GROUP BY `description`
ORDER BY COUNT(*) DESC
LIMIT 10;

-- c. What are the top 10 procedures with the highest average base cost and the number of times they were performed?

SELECT `description`, COUNT(*) AS cnt, AVG(base_cost) AS avg_b_cost
FROM procedures_staging
GROUP BY `description`
ORDER BY avg_b_cost DESC
LIMIT 10;

-- d. What is the average total claim cost for encounters, broken down by payer?

SELECT p.name AS p_name,
       AVG(e.total_claim_cost) AS avg_claim_cost
FROM encounters_staging2 e
LEFT JOIN payers_staging p ON e.payer = p.id
GROUP BY p.name
ORDER BY avg_claim_cost DESC;

-- OBJECTIVE 3: PATIENT BEHAVIOUR ANALYSIS
-- a. How many unique patients were admitted each quarter over time?

SELECT YEAR(start) AS yr,
QUARTER(`start`) AS qut,
COUNT(DISTINCT(patient)) AS no_of_pat
FROM encounters_staging2
GROUP BY YEAR(start),
         QUARTER(`start`);

-- b. How many patients were readmitted within 30 days of a previous encounter?

WITH patient_visits AS (
    SELECT 
        patient,
        `start` AS cur_start,
        LAG(`stop`) OVER (
            PARTITION BY patient 
            ORDER BY `start`
        ) AS previous_stop
    FROM encounters_staging2
),
readmission_calc AS (
    SELECT 
        patient,
        TIMESTAMPDIFF(DAY, previous_stop, cur_start) AS days_between_visits
    FROM patient_visits
    WHERE previous_stop IS NOT NULL            -- Exclude the very first visit of each patient
)
SELECT  COUNT(*) AS readmitted_patients_count
FROM readmission_calc
WHERE days_between_visits >= 0 AND days_between_visits <= 30;
       
       
-- c. Which patients had the most readmissions?
WITH patient_visits AS (
    SELECT 
        patient,
        `start` AS cur_start,
        LAG(`stop`) OVER (
            PARTITION BY patient 
            ORDER BY `start`
        ) AS previous_stop
    FROM encounters_staging2
),
readmission_calc AS (
    SELECT 
        patient,
        TIMESTAMPDIFF(DAY, previous_stop, cur_start) AS days_between_visits
    FROM patient_visits
    WHERE previous_stop IS NOT NULL              -- Exclude the very first visit of each patient
),
name_cte AS (
SELECT patient, COUNT(*) AS readmitted_patients_count              /* Name of patient*/
FROM readmission_calc
WHERE days_between_visits >= 0 AND days_between_visits <= 30
GROUP BY patient
ORDER BY COUNT(*) DESC
)
-- SELECT CONCAT(p.first,' ',p.last)  AS p_name
-- FROM patients_staging p
-- JOIN name_cte n ON p.id = n.patient;

SELECT patient, COUNT(*) AS readmitted_patients_count
FROM readmission_calc
WHERE days_between_visits >= 0 AND days_between_visits <= 30
GROUP BY patient
ORDER BY COUNT(*) DESC
LIMIT 10;


       





























