-- =====================================================================
-- 01_import_and_filter.sql
-- Load the OSHA Severe Injury Reports file unchanged, verify the date
-- format, and filter to incidents dated in calendar year 2024.
--
-- Run with:  mysql --local-infile=1 -u <user> -p < sql/01_import_and_filter.sql
-- Tested on MariaDB 10.11 (MySQL-compatible syntax; no MariaDB-only features).
-- =====================================================================
-- Import assumptions (checked against the file before writing this script):
--   * Comma-delimited, every field double-quoted, header in line 1 (removed after load, see below).
--   * Rows end in CRLF. Narratives can contain embedded CRLF inside quotes.
--   * EventDate is text in m/d/yyyy form (e.g. 1/1/2015, 11/30/2025).
--   * Code columns are numeric-looking but variable length (1-4 digits), so
--     they are kept as text to avoid losing meaning and to match the manual.
--   * The source file is never modified; everything below reads from it.
-- Set @src_file to the path of the extracted CSV before running.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS worksafe CHARACTER SET utf8mb4;
USE worksafe;

-- ---------------------------------------------------------------------
-- 1. Raw landing table: every column as text, exactly as supplied
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS raw_sir;
CREATE TABLE raw_sir (
    id                      VARCHAR(20),
    upa                     VARCHAR(20),
    event_date              VARCHAR(20),
    employer                VARCHAR(255),
    address1                VARCHAR(255),
    address2                VARCHAR(255),
    city                    VARCHAR(100),
    state                   VARCHAR(60),
    zip                     VARCHAR(20),
    latitude                VARCHAR(30),
    longitude               VARCHAR(30),
    primary_naics           VARCHAR(20),
    hospitalized            VARCHAR(10),
    amputation              VARCHAR(10),
    loss_of_eye             VARCHAR(10),
    inspection              VARCHAR(30),
    final_narrative         TEXT,
    nature                  VARCHAR(10),
    nature_title            VARCHAR(255),
    part_of_body            VARCHAR(10),
    part_of_body_title      VARCHAR(255),
    event                   VARCHAR(10),
    event_title             VARCHAR(255),
    source                  VARCHAR(10),
    source_title            VARCHAR(255),
    secondary_source        VARCHAR(10),
    secondary_source_title  VARCHAR(255),
    federal_state           VARCHAR(10)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA LOCAL INFILE '/path/to/January2015toNovember2025.csv'
INTO TABLE raw_sir
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\r\n';

-- IGNORE 1 LINES is deliberately NOT used. In testing it also swallowed the
-- first line of the first data record (a narrative containing an embedded CRLF),
-- leaving a malformed row. Instead the header is loaded as a data row and removed.
DELETE FROM raw_sir WHERE id = 'ID' AND event_date = 'EventDate';

-- ---------------------------------------------------------------------
-- 2. Row counts and date handling BEFORE filtering
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS original_row_count FROM raw_sir;

-- Any EventDate that does not parse as m/d/yyyy? (expected: 0)
SELECT COUNT(*) AS unparseable_event_dates
FROM raw_sir
WHERE STR_TO_DATE(event_date, '%m/%d/%Y') IS NULL;

SELECT MIN(STR_TO_DATE(event_date, '%m/%d/%Y')) AS first_event_date,
       MAX(STR_TO_DATE(event_date, '%m/%d/%Y')) AS last_event_date
FROM raw_sir;

-- Rows per year: confirms 2024 is a complete calendar year in the file
SELECT YEAR(STR_TO_DATE(event_date, '%m/%d/%Y')) AS event_year,
       COUNT(*) AS rows_in_year
FROM raw_sir
GROUP BY event_year
ORDER BY event_year;

-- ---------------------------------------------------------------------
-- 3. Filtered working table: incident dates 1 Jan - 31 Dec 2024
--    Typed columns; employer name, street address and coordinates are not
--    carried forward because the audit does not need them.
--    Text is stored as supplied; trimming is handled in 02_*.sql.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS sir_2024;
CREATE TABLE sir_2024 AS
SELECT
    id                                         AS incident_id,
    upa                                        AS upa_id,
    STR_TO_DATE(event_date, '%m/%d/%Y')        AS event_date,
    state,
    primary_naics,
    CAST(hospitalized AS DECIMAL(3,2))         AS hospitalized,
    CAST(amputation   AS DECIMAL(3,2))         AS amputation,
    CAST(loss_of_eye  AS DECIMAL(3,2))         AS loss_of_eye,
    federal_state,
    final_narrative,
    nature, nature_title,
    part_of_body, part_of_body_title,
    event, event_title,
    source, source_title,
    secondary_source, secondary_source_title
FROM raw_sir
WHERE STR_TO_DATE(event_date, '%m/%d/%Y') >= '2024-01-01'
  AND STR_TO_DATE(event_date, '%m/%d/%Y') <  '2025-01-01';

ALTER TABLE sir_2024 ADD INDEX idx_incident (incident_id);

-- ---------------------------------------------------------------------
-- 4. Verification: counts and range of the filtered table
-- ---------------------------------------------------------------------
SELECT (SELECT COUNT(*) FROM raw_sir)  AS original_rows,
       (SELECT COUNT(*) FROM sir_2024) AS rows_2024,
       (SELECT COUNT(*) FROM raw_sir) - (SELECT COUNT(*) FROM sir_2024) AS rows_excluded;

SELECT MIN(event_date) AS min_date_2024,
       MAX(event_date) AS max_date_2024,
       SUM(YEAR(event_date) <> 2024) AS rows_outside_2024   -- expected: 0
FROM sir_2024;
