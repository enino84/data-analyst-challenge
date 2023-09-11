DROP TABLE IF EXISTS ratio_evolution_pro_sup;

CREATE TABLE ratio_evolution_pro_sup AS 
/*
   Only supervisors
*/
WITH only_supervisors AS (
    SELECT TRIM(series_id) AS series_id, series_title
    FROM series
    WHERE seasonal = 'S' AND LOWER(CAST(series_title AS VARCHAR)) LIKE 'production and nonsupervisory employees, thousands,%'
),

/*
   All employees
*/
all_employees AS (
    SELECT TRIM(series_id) AS series_id, series_title
    FROM series
    WHERE seasonal = 'S' AND LOWER(CAST(series_title AS VARCHAR)) LIKE 'all employees, thousands,%'
),

data_ready AS (
    SELECT TRIM(series_id) AS series_id, year, SUBSTRING(period FROM 2 FOR 2) AS month, value
    FROM data_
),

data_month_year_supervisors AS (
    SELECT *, TO_CHAR(TO_DATE(month, 'MM'), 'Month') || ' ' || year AS month_year
    FROM only_supervisors INNER JOIN data_ready USING (series_id)
),

data_month_year_all AS (
    SELECT *, TO_CHAR(TO_DATE(month, 'MM'), 'Month') || ' ' || year AS month_year
    FROM all_employees INNER JOIN data_ready USING (series_id)
),

agg_data_supervisor AS (
    SELECT month, year, month_year AS date, SUM(value) / 1000 AS sum_sup
    FROM data_month_year_supervisors
    GROUP BY month_year, year, month
),

agg_data_all AS (
    SELECT month_year AS date, SUM(value) / 1000 AS sum_all
    FROM data_month_year_all
    GROUP BY month_year, year, month
),

agg_non_supervisors AS (
    SELECT b.month, b.year, a.date, (a.sum_all - b.sum_sup)/b.sum_sup AS "ratioInThousands", 
    a.sum_all, b.sum_sup
    FROM agg_data_all a INNER JOIN agg_data_supervisor b USING (date)

)

SELECT date, "ratioInThousands"
FROM agg_non_supervisors
ORDER BY year, month;



