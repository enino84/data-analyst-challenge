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


