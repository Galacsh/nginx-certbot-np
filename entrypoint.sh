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

# start nginx
/docker-entrypoint.sh "$1"

wait_nginx_start

/scripts/obtain-cert.sh
/scripts/renew-cert.sh &

# ============================
# == Restart nginx as PID 1 ==
# ============================

echo "Stopping nginx..."

# stop nginx and wait
nginx -s stop
wait_nginx_stop

exec "$@"
