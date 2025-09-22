# Dockerfile for MCR (MATLAB Compiler Runtime) version
# Phase 3 - To be implemented

FROM mathworks/matlab-runtime:latest

# Add application files
COPY . /app
WORKDIR /app

# Make run script executable
RUN chmod +x /app/run

# Entry point
ENTRYPOINT ["/app/run"]