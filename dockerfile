# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set workdir
WORKDIR /app

# Install build deps and system deps needed by some packages (if any)
RUN apt-get update && apt-get install -y build-essential libpq-dev --no-install-recommends && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy project
COPY . /app/
RUN python manage.py migrate --noinput

# 1. Create a dedicated non-root user (appuser and appuser_group)
RUN groupadd -r appuser_group && useradd -r -g appuser_group appuser

# 2. Grant ownership to the non-root user over the application directory (where db.sqlite3 is created)
RUN chown -R appuser:appuser_group /app

# 3. Switch the process execution to the non-root user
USER appuser

# --- SECURITY FIXES END HERE ---

# Expose port
EXPOSE 8000

# Start using gunicorn (Note: You may need gunicorn in requirements.txt)
CMD ["gunicorn", "--chdir", "/app", "jobtracker.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "2"]