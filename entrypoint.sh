#!/bin/sh

# ========================================================

echo "Starting nginx-certbot..."
set -e

# ========================================================
# Helper functions
# ========================================================

wait_nginx_start() {
  while ! pgrep -l nginx | grep master >/dev/null; do
    echo "Waiting for nginx to start..."
    sleep 1
  done
  echo "nginx started."
}

wait_nginx_stop() {
  echo "Waiting for nginx to stop..."
  echo "Will use netstat to check if nginx is still running."
  while netstat -tulnp | grep nginx >/dev/null; do
    sleep 1
  done
  echo "nginx stopped."
}

# ========================================================

# Generate dh parameters for each domain.
/scripts/setup-dhparam.sh

# Start auto renewal service.
/scripts/renew-cert.sh &

# start nginx
nginx
wait_nginx_start

# Try obtaining certs.
/scripts/obtain-cert.sh

echo "Stopping nginx..."

# stop nginx and wait
nginx -s stop
wait_nginx_stop

# =================================================
# == Restart nginx with other entrypoint scripts ==
# =================================================

# start nginx
exec /docker-entrypoint.sh "$@"
