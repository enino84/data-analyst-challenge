-- Create a new table with columns defined by the CSV file

DROP TABLE IF EXISTS data_;
DROP TABLE IF EXISTS series;

CREATE TABLE data_ (
    series_id VARCHAR(15),
    year INT,
    period VARCHAR(5),
    value FLOAT,
    footnote_codes VARCHAR(30)
);

CREATE TABLE series (
    series_id VARCHAR(15),
    supersector_code VARCHAR(2),
    industry_code VARCHAR(8),
    data_type_code VARCHAR(2),
    seasonal VARCHAR(1),
    series_title VARCHAR(255),
    footnote_codes VARCHAR(255),
    begin_year INT,
    begin_period VARCHAR(3),
    end_year INT,
    end_period VARCHAR(3)
);

-- Copy data from a CSV file into the table
\COPY data_ FROM 'ce.data.0.AllCESSeries' DELIMITER E'\t' CSV HEADER;

\COPY series FROM 'ce.series' DELIMITER E'\t' CSV HEADER;


