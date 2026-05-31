FROM python:3.11-slim AS production

# Security: Create non-root user group and user
RUN groupadd -r appgroup && useradd -r -g appgroup -d /app -s /sbin/nologin appuser

WORKDIR /app

# Install system-wide utilities as root
RUN apt-get update && \
    apt-get install -y --no-install-recommends dumb-init && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy requirements file and install dependencies globally as root
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files and templates with proper ownership
COPY --chown=appuser:appgroup app_secure.py .
COPY --chown=appuser:appgroup templates/ ./templates/

# Security: Set up specific writable directory for SQLite/data if needed
RUN mkdir -p /app/data && chown appuser:appgroup /app/data

# Switch context to the unprivileged user
USER appuser

# Expose on the designated high port
EXPOSE 8000

ENTRYPOINT ["dumb-init", "--"]
CMD ["gunicorn", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "2", \
     "--timeout", "30", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--log-level", "info", \
     "app_secure:app"]
