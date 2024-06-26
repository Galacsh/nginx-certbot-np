#!/bin/sh

# If MODE is dev, exit right away
if [ "$MODE" = "dev" ]; then
  echo "Will not try to renew certificates in dev mode."
  exit 0
fi

# ================================================

checkNginx() {
  # using pgrep -l nginx | grep master
  if pgrep -l nginx | grep master > /dev/null; then
    is_nginx_running=1
  else
    is_nginx_running=0
  fi
}

# Wait for NGINX to start
is_nginx_running=0

# wait for nginx to start
while [ $is_nginx_running -eq 0 ]; do
  echo "Waiting for NGINX to start..."
  sleep 1 && checkNginx
done
echo "NGINX started."

# ================================================

# How long to wait before retrying to obtain or renew certificates.
# Get the value from the environment variable, default to 24 hours.
RETRY_INTERVAL="${RETRY_INTERVAL:-86400}"

# ========================
# == Renew certificates ==
# ========================

# Main loop to renew certificates every 24 hours
while true; do
  # Wait before next renewal check
  echo "Waiting before renewal check..."
  sleep "$RETRY_INTERVAL"

  echo "Trying to renew certificates..."
  certbot renew --deploy-hook="/scripts/reload-nginx.sh"
done
