DROP TABLE IF EXISTS women_in_government;

CREATE TABLE women_in_government AS 
/*
   This table is created to store data related to government positions held by women.
   We are specifically interested in seasonal data.
   The selection of records is based on the series_title field, which should contain 
   the keywords 'women' and 'government' (women before government given the field structure).
*/
WITH only_women AS (
    SELECT TRIM(series_id) AS series_id, series_title
    FROM series
    WHERE seasonal = 'S' AND LOWER(CAST(series_title AS VARCHAR)) LIKE '%women%government%'
),

/*
   In this section, we prepare the data for further processing.
   We remove the 'M' character from the month in the period field.
*/
data_ready AS (
    SELECT TRIM(series_id) AS series_id, year, SUBSTRING(period FROM 2 FOR 2) AS month, value
    FROM data_
),

/*
   Here, we create a new field named 'month_year' that combines the month and year.
   We perform an inner join between the only_women data and the data_ready one via 'series_id'
*/
data_month_year AS (
    SELECT *, TO_CHAR(TO_DATE(month, 'MM'), 'Month') || ' ' || year AS month_year
    FROM only_women INNER JOIN data_ready USING (series_id)
)

/*
   Finally, we organize/group the data by 'month_year' (and 'year', 'month'), summing up values and converting them to thousands.
   The result is ordered by year and month.
*/
SELECT month_year AS date, SUM(value) / 1000 AS "valueInThousands"
FROM data_month_year
GROUP BY month_year, year, month
ORDER BY year, month;



