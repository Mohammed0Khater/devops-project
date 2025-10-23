# ---- Stage 1: The Builder ----
# Use a full-featured image to install dependencies
FROM python:3.9-slim as builder

# Set the working directory
WORKDIR /app

# Copy the requirements file and install them into a temporary directory
# This layer will be cached if requirements.txt doesn't change
COPY requirements.txt .
RUN pip install --no-cache-dir --target /opt/pip-packages -r requirements.txt


# ---- Stage 2: The Final Image ----
# Use a minimal base image for the final production image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy the installed packages from the builder stage
COPY --from=builder /opt/pip-packages /usr/local/lib/python3.9/site-packages

# Copy the rest of the application code
COPY . .

# Expose the ports
EXPOSE 8080
EXPOSE 8081

# Run the application
CMD ["python", "app.py"]
