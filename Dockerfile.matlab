# Dockerfile for MATLAB development version
# Phase 3 - To be implemented

FROM mathworks/matlab:latest

# Add application files
COPY . /app
WORKDIR /app

# Make run script executable
RUN chmod +x /app/run

# Entry point
ENTRYPOINT ["/app/run"]