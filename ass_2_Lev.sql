
CREATE SCHEMA ass_2;
use ass_2;
create table personal(
name VARCHAR(200), profession VARCHAR(200), boss VARCHAR(200));

CREATE TABLE motivation(
name VARCHAR(200), work_incentive VARCHAR(200), was_detained VARCHAR(200));

CREATE TABLE potential_hostages( name VARCHAR(200), num_children INT,
 fam_status VARCHAR(200));
 
 LOAD DATA LOCAL INFILE 
 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/members.csv' INTO TABLE personal
 FIELDS TERMINATED BY ','
 LINES TERMINATED BY '\r\n'
 IGNORE 1 LINES;
 Select * from personal;
 SET GLOBAL local_infile = 1;
 LOAD DATA LOCAL INFILE 
 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/motivation.csv' INTO TABLE motivation
 FIELDS TERMINATED BY ','
 LINES TERMINATED BY '\r\n'
 IGNORE 1 LINES;
 LOAD DATA LOCAL INFILE 
 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/additional_motivation.csv'
 INTO TABLE potential_hostages
 FIELDS TERMINATED BY ','
 LINES TERMINATED BY '\r\n'
 IGNORE 1 LINES;
Select * from personal;
Select * from motivation;
Select * from potential_hostages
order by name asc;

/* NON-OPTIMIZED on purpose */
EXPLAIN analyze
WITH b AS (
  SELECT
         p.name, p.boss, p.profession,
         m.work_incentive, m.was_detained,
         h.num_children, h.fam_status
  FROM personal p
  /* functions on join keys (kills indexes) */
  LEFT JOIN motivation m
    ON TRIM(LOWER(p.name)) = TRIM(LOWER(m.name))
  /* needless CONCAT on key (also unsargable) */
  LEFT JOIN potential_hostages h
    ON CONCAT('', p.name, '') = CONCAT('', h.name, '')
  WHERE 1=1
    /* leading wildcards + function on column */
    AND LOWER(p.profession) LIKE '%police_officer%'
    /* redundant LIKE instead of equality */
    AND LOWER(m.work_incentive) LIKE '%just_salary%'
    /* NEW to match your filter (mismatch #2) */
    AND m.was_detained = 'was_detained'
    /* vague boss filter so '%Lev%' must appear anywhere */
    AND p.boss LIKE '%Lev%'
    /* another function + leading wildcard */
    AND LOWER(h.fam_status) LIKE '%single%'
    /* redundant semi-join subquery duplicating a join filter */
    AND p.name IN (SELECT name FROM motivation
                   WHERE LOWER(work_incentive) LIKE '%just_salary%')
)
SELECT *
FROM b
/* heavy, nondeterministic ordering */
ORDER BY RAND();

ALTER TABLE personal
ADD personal_id INT AUTO_INCREMENT,
ADD PRIMARY KEY (personal_id);

ALTER TABLE motivation
ADD motivation_id INT AUTO_INCREMENT,
ADD PRIMARY KEY (motivation_id);

ALTER TABLE potential_hostages
ADD potential_hostages_id INT AUTO_INCREMENT,
ADD PRIMARY KEY (potential_hostages_id);

select * from personal;
select * from motivation;
select * from potential_hostages;


CREATE INDEX idx_1
ON personal (name, profession, boss);
CREATE INDEX idx_2
ON motivation (name, work_incentive, was_detained);
CREATE INDEX idx_3
ON potential_hostages (name, fam_status);


WITH lev_policia AS(
SELECT * FROM personal USE INDEX (idx_1)
WHERE profession = 'police_officer' AND boss = 'Lev'
),
probably_rat AS(
SELECT * FROM motivation USE INDEX (idx_2)
WHERE work_incentive = 'just_salary' AND was_detained = 'was_detained'
),
lone_wolf AS(
SELECT * FROM potential_hostages WHERE fam_status = 'single'
)

/*+JOIN_ORDER(l,pr, lw)  */ #Order of joins for more decen optimization

SELECT l.name, boss, profession, work_incentive, was_detained,num_children,fam_status
FROM lev_policia l  
JOIN probably_rat pr
	ON l.name = pr.name
JOIN lone_wolf lw
	ON pr.name = lw.name;



