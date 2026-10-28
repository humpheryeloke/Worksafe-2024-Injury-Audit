-- =====================================================================
-- 00_load_oiics_reference.sql
-- Load the OIICS Version 3.03 code lists (Nature, Part of body, Event,
-- Source) into a lookup table. The CSV was extracted from the BLS Excel
-- manual (worksheets 2.b, 3.b, 4.b, 5.b): field, code, title, hierarchy.
-- Source/Secondary source share one code list (worksheet 5.b).
-- Run after 01_import_and_filter.sql.
-- =====================================================================
USE worksafe;

DROP TABLE IF EXISTS oiics_ref;
CREATE TABLE oiics_ref (
    field      VARCHAR(10),      -- nature | part | event | source
    code       VARCHAR(10),
    title      VARCHAR(400),
    hierarchy  VARCHAR(5),       -- manual level: 1s, 2s, 2, 3s, 3, 4 ...
    PRIMARY KEY (field, code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA LOCAL INFILE '/path/to/documentation/reference/oiics_303_codes.csv'
INTO TABLE oiics_ref
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Title comparison key: lower-case letters and digits only. The OSHA file
-- drops the em dash used in the manual titles, so punctuation is ignored.
ALTER TABLE oiics_ref ADD COLUMN title_key VARCHAR(400);
UPDATE oiics_ref SET title_key = LOWER(REGEXP_REPLACE(title, '[^A-Za-z0-9]', ''));

SELECT field, COUNT(*) AS codes_loaded FROM oiics_ref GROUP BY field;
