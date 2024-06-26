#!/bin/sh

# ========================================================

echo "Starting nginx-certbot..."
set -e

# ========================================================

# start nginx
/docker-entrypoint.sh nginx

# obtain certificates
/scripts/obtain-cert.sh

# start background renew & nginx reload
/scripts/renew-cert.sh &

# ============================
# == Restart nginx as PID 1 ==
# ============================

echo "Stopping NGINX..."
# stop nginx and wait
nginx -s stop
while netstat -tulnp | grep nginx; do
    sleep 1
done
echo "NGINX stopped."

echo "Starting NGINX..."
exec nginx -g 'daemon off;'
