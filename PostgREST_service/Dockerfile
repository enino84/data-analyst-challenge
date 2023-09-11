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
