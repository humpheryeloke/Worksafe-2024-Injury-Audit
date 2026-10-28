-- =====================================================================
-- 02b_select_review_sample.sql
-- Select the 100-incident review sample from the 2024 data.
-- Design: stratified by Event division (first digit of the recorded Event
-- code), with a fixed allocation per stratum. Inside each stratum, records
-- are ranked so that different Nature groups are used before any Nature
-- group is repeated, which spreads the sample across injury types.
-- Selection is reproducible: ordering uses MD5 of a fixed seed + incident ID,
-- not RAND().
-- THE SAMPLE IS NOT STATISTICALLY REPRESENTATIVE (see documentation/methodology.md).
-- =====================================================================
USE worksafe;

SET @seed = 'WS2024-';

-- Fixed allocation (sums to 100). Rule: minimum 6 per Event division, remaining
-- places roughly proportional to division size (division 6 and 4 are largest).
DROP TABLE IF EXISTS sample_allocation;
CREATE TABLE sample_allocation (event_division CHAR(1) PRIMARY KEY, n_to_select INT);
INSERT INTO sample_allocation VALUES
    ('6', 30), ('4', 22), ('2', 11), ('5', 10), ('3', 7), ('1', 7), ('7', 7), ('9', 6);

-- Sampling frame: all 2024 records except those excluded by the data-quality audit
--   DQ08: narrative under 60 characters; DQ06: narrative text repeated on another record
DROP TABLE IF EXISTS sampling_frame;
CREATE TABLE sampling_frame AS
SELECT s.incident_id, s.event_date, s.final_narrative,
       LEFT(s.event, 1)  AS event_division,
       LEFT(s.nature, 3) AS nature_group,
       MD5(CONCAT(@seed, s.incident_id)) AS pick_hash
FROM sir_2024 s
WHERE CHAR_LENGTH(s.final_narrative) >= 60
  AND MD5(s.final_narrative) NOT IN (
        SELECT MD5(final_narrative) FROM sir_2024
        GROUP BY MD5(final_narrative) HAVING COUNT(*) > 1);

SELECT event_division, COUNT(*) AS frame_records FROM sampling_frame GROUP BY event_division ORDER BY event_division;
SELECT COUNT(*) AS frame_total FROM sampling_frame;

-- Rank inside each stratum: first record of each Nature group, then second, ...
DROP TABLE IF EXISTS review_sample;
CREATE TABLE review_sample AS
SELECT ranked.incident_id, ranked.event_date, ranked.event_division, ranked.nature_group,
       ranked.final_narrative
FROM (
    SELECT f.*,
           ROW_NUMBER() OVER (PARTITION BY f.event_division
                              ORDER BY nr.rr, f.pick_hash) AS pick_order
    FROM sampling_frame f
    JOIN (SELECT incident_id,
                 ROW_NUMBER() OVER (PARTITION BY event_division, nature_group ORDER BY pick_hash) AS rr
          FROM sampling_frame) nr ON nr.incident_id = f.incident_id
) ranked
JOIN sample_allocation a ON a.event_division = ranked.event_division
WHERE ranked.pick_order <= a.n_to_select;

-- Stable review order: review_id 1..100, shuffled across strata by hash
ALTER TABLE review_sample ADD COLUMN review_id INT;
SET @n = 0;
UPDATE review_sample
SET review_id = (@n := @n + 1)
ORDER BY MD5(CONCAT(@seed, 'order-', incident_id));
ALTER TABLE review_sample ADD PRIMARY KEY (review_id), ADD UNIQUE KEY uq_incident (incident_id);

-- Checks
SELECT COUNT(*) AS sample_size, COUNT(DISTINCT incident_id) AS distinct_incidents FROM review_sample;
SELECT event_division, COUNT(*) AS sampled FROM review_sample GROUP BY event_division ORDER BY event_division;
SELECT COUNT(DISTINCT nature_group) AS nature_groups_in_sample FROM review_sample;
