#!/bin/sh

# ========================================================

echo "Starting nginx-certbot..."
set -e

# ========================================================
# Helper functions
# ========================================================

waitNginxStart() {
  while ! pgrep -l nginx | grep master > /dev/null; do
    echo "Waiting for nginx to start..."
    sleep 1
  done
  echo "nginx started."
}

waitNginxStop() {
  # check if nginx released the port
  while netstat -tulnp | grep nginx; do
      sleep 1
  done
  echo "nginx started."
}

# ========================================================

# start nginx
/docker-entrypoint.sh "$1"

waitNginxStart

/scripts/obtain-cert.sh
/scripts/renew-cert.sh &

# ============================
# == Restart nginx as PID 1 ==
# ============================

echo "Stopping nginx..."

# stop nginx and wait
nginx -s stop
waitNginxStop

exec "$@"
