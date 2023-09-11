# Nimble Gravity

## Data Analyst Challenge 2022

The purpose of this repository is to create a system capable of leveraging the CES time series dataset to address the following business inquiries:

1. How was the evolution of women in goverment during time? 
2. How was the evolution of the ratio "production employees / supervisory employees" 
during time? 

To achieve these objectives, we employ the following methodology:

- **Utilizing a Postgres Database System:** We employ a Postgres database system to efficiently import and organize the requisite flat files, which can be accessed at https://www.bls.gov/data/#employment. These files are transformed into structured tables within the database.

- **Constructing a Service for Flat File Loading:** We develop a service that facilitates the seamless loading of flat files into the aforementioned Postgres database. This ensures data integrity and accessibility.

- **Establishing a PostgREST Access Point:** To enable straightforward data retrieval and interaction, we set up a PostgREST access point. This interface simplifies the process of querying and extracting data from the database.

In all cases, I employ Docker containers because they are portable, consistent, scalable, secure, and efficient. These qualities make them a valuable tool for developing, deploying, and managing applications. So, the Docker daemon must be running for the following steps to work properly.

# Proposed solution

Following I detail each of these steps:

I generally avoid using Python in most cases. However, there are specific scenarios where I do utilize it:

1. **Data Validation:** I use it as a verification tool to ensure the data has been loaded correctly.

2. **Creating Business-Related Visuals:** I need generate some plots and charts that are directly relevant to our business objectives. 

Apart from these specific situations, I don't use Python and opt for SQL + postgres tools.

## Utilizing a Postgres Database System

I create a Docker container that holds the Postgres database system. The Dockerfile looks as follows (which self explains its content)

```docker
# Use the official PostgreSQL image as the base image
FROM postgres:latest

# Set environment variables for PostgreSQL
ENV POSTGRES_DB nimble
ENV POSTGRES_USER admin
ENV POSTGRES_PASSWORD admin

EXPOSE 5432

# Start the PostgreSQL server
CMD ["postgres"]
```

Go to the `Postgres_service` folder and type:
```bash
docker build -t db_img .
```

This will build an image using the latest version of Postgres. Then create the container:
```bash
docker run -p 8000:5432 db_img
```

Here, we have let the host port 8000 to map to the port 5432 within the container. If everything works fine, the database `numble` will be created, the service will be launched, and you should see the following prompt:
```bash

enino@DESKTOP-NDV46PT MINGW64 ~/Documents/Nimble/Postgres_service
$ docker run -p 8000:5432 bd_img
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

...

Success. You can now start the database server using:

    pg_ctl -D /var/lib/postgresql/data -l logfile start

initdb: warning: enabling "trust" authentication for local connections
initdb: hint: You can change this by editing pg_hba.conf or using the option -A, or --auth-local and --auth-host, the next time you run initdb.
waiting for server to start....2023-09-11 09:57:24.317 UTC [48] LOG:  starting PostgreSQL 15.4 (Debian 15.4-1.pgdg120+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
2023-09-11 09:57:24.321 UTC [48] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2023-09-11 09:57:24.333 UTC [51] LOG:  database system was shut down at 2023-09-11 09:57:24 UTC 
2023-09-11 09:57:24.340 UTC [48] LOG:  database system is ready to accept connections
```

## Constructing a Service for Flat File Loading

After setting up the database system, the next step is populating it with the necessary flat files sourced from https://www.bls.gov/data/#employment. These files are indispensable for addressing our business inquiries, and the specific files we require are:

1. `ce.data.0.AllCESSeries`
2. `ce.series`

These files serve as the essential data inputs that enable us to answer the provided business questions.

Go to the `Migration_service` folder and type
```bash
docker build -t md_img .
```

This will build an image of an `alpine` system that will load the data into the database `numble`. The Dockerfile for this system reads:
```docker
# Use the official Alpine Linux image as the base image
FROM alpine:latest

# Install PostgreSQL client
RUN apk --no-cache add postgresql-client

# Create a directory for your PostgreSQL scripts
RUN mkdir -p /app/files

# Set the working directory to /app/scripts
WORKDIR /app/files

# Expose a volume for mounting SQL scripts from your local machine
VOLUME /app/files

COPY files/* /app/files/

# Make the jobs.sh file executable
RUN chmod +x /app/files/jobs.sh

# Start the jobs.sh script when the container starts
CMD ["/app/files/jobs.sh"]
```

As can be seen, the script file `jobs.sh` will take care of all the processes to be executed. I employ the Postgres client `psql` to remotely execute commands on the `numble` database. This file looks like:
```bash
#!/bin/sh -x

# Get the password from an environment variable
export PGPASSWORD="admin"

echo "* Step01 - Creating source tables, and migrating the data"

psql -h localhost -p 8000 -U admin -d nimble -f step01_copying_data.sql

echo "* Step01 - Ready"

echo "* Step02 - Creating the women_in_government table"

psql -h localhost -p 8000 -U admin -d nimble -f step02_creating_women_in_government.sql

echo "* Step02 - Ready"

echo "* Step03 - Creating the ratio_evolution_pro_sup table"

psql -h localhost -p 8000 -U admin -d nimble -f step03_creating_ratio_evolution_pro_sup.sql

echo "* Step03 - Ready"
```

Wherein:

1. The `step01_copying_data.sql` copy the information from the flat files to the database `numble`:

```sql
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
```

Note that, we employ the `\COPY` function to map flat files from the local container into the remote database service in the host machine.

2. The `step02_creating_women_in_government.sql` contains the logic to build the table `women_in_government` to answer the first busnisess question: how was the evolution of women in goverment during time? 
```sql
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
```

The logic is simple: we query relevants series_id related to women job positions, cross that with the historical data, and then perform the aggregations by year and month. Additional work is done just to present the data nicely.


3. The `step03_creating_ratio_evolution_pro_sup.sql` file takes care of creating a table to answer the question: how was the evolution of the ratio "production employees / supervisory employees" during time?, it looks as follows:
```sql
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
```

The approach mirrors the one used for 'women_in_government.' Initially, we gather records pertaining to both supervisor and all job positions. Subsequently, we subtract the supervisor-related job positions from the total job count to isolate the non-supervisor positions. From this point, we calculate the desired ratio.

We then perform the migration by typing:

```bash
docker run --network="host" md_img
```

If everything works fine, you'll see the following prompt:
```bash
enino@DESKTOP-NDV46PT MINGW64 ~/Documents/Nimble/Migration_service
$ docker run --network="host" md_img
+ export 'PGPASSWORD=admin'
+ echo '* Step01 - Creating source tables, and migrating the data'
+ psql -h localhost -p 8000 -U admin -d nimble -f step01_copying_data.sql
* Step01 - Creating source tables, and migrating the data
DROP TABLE
psql:step01_copying_data.sql:3: NOTICE:  table "data_" does not exist, skipping
DROP TABLE
psql:step01_copying_data.sql:4: NOTICE:  table "series" does not exist, skipping
CREATE TABLE
CREATE TABLE
COPY 8237965
COPY 23981
* Step01 - Ready
* Step02 - Creating the women_in_government table
+ echo '* Step01 - Ready'
+ echo '* Step02 - Creating the women_in_government table'
+ psql -h localhost -p 8000 -U admin -d nimble -f step02_creating_women_in_government.sql       
DROP TABLE
psql:step02_creating_women_in_government.sql:1: NOTICE:  table "women_in_government" does not exist, skipping
SELECT 716
* Step02 - Ready
* Step03 - Creating the ratio_evolution_pro_sup table
+ echo '* Step02 - Ready'
+ echo '* Step03 - Creating the ratio_evolution_pro_sup table'
+ psql -h localhost -p 8000 -U admin -d nimble -f step03_creating_ratio_evolution_pro_sup.sql   
psql:step03_creating_ratio_evolution_pro_sup.sql:1: NOTICE:  table "ratio_evolution_pro_sup" does not exist, skipping
DROP TABLE
SELECT 1016
* Step03 - Ready
+ echo '* Step03 - Ready'
```
## Establishing a PostgREST Access Point

In the final stage, we create a container to publish a PostgREST service. The Dockerfile looks as follows:
```docker
# Use the official PostgREST image as the base image
FROM postgrest/postgrest:latest

# Expose the default PostgREST port (3000)
EXPOSE 3000

# Define environment variables for PostgREST
ENV PGRST_DB_URI="postgres://admin:admin@localhost:8000/nimble"
ENV PGRST_DB_SCHEMA="public"
ENV PGRST_DB_ANON_ROLE="anon"

# Start PostgREST
CMD ["postgrest"]
```

Go to the `PostgREST_service` folder and type
```bash
docker build -t pr_img .
```
to build the PostgREST image. From here, we launch the service via:
```bash
docker run --network="host" pr_img
```

If everything works correctly, you should see the following prompt:
```bash
enino@DESKTOP-NDV46PT MINGW64 ~/Documents/Nimble/PostgREST_service
$ docker run --network="host" pr_img
11/Sep/2023:10:02:00 +0000: Starting PostgREST 11.2.0...
11/Sep/2023:10:02:00 +0000: Attempting to connect to the database...
11/Sep/2023:10:02:00 +0000: Connection successful
11/Sep/2023:10:02:00 +0000: Listening on port 3000
11/Sep/2023:10:02:00 +0000: Config reloaded
11/Sep/2023:10:02:00 +0000: Listening for notifications on the pgrst channel
11/Sep/2023:10:02:00 +0000: Schema cache loaded
```

The system will be ready to receive requests.

# Final plots/comments

By analyzing the plots within the 'Migration_Tester.ipynb' notebook, it becomes evident that there has been a significant increase in the participation of women in government positions. 

![](images/women_in_government.png)

Furthermore, the ratio between production employees and supervisory employees has gradually approached unity, suggesting that individuals are becoming increasingly self-sufficient and requiring minimal supervision to perform their tasks effectively.

![](images/sup_no_sup_ratop.png)

