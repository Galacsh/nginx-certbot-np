#!/bin/sh

# If MODE is not prod, exit right away
if [ "$MODE" != "prod" ]; then
  echo "Will not try to renew certificates in dev mode."
  exit 0
fi

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
