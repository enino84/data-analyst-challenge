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
