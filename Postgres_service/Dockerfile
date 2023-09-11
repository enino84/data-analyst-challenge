# Use the official PostgreSQL image as the base image
FROM postgres:latest

# Set environment variables for PostgreSQL
ENV POSTGRES_DB nimble
ENV POSTGRES_USER admin
ENV POSTGRES_PASSWORD admin

EXPOSE 5432

# Start the PostgreSQL server
CMD ["postgres"]
