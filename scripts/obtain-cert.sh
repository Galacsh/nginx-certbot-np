#!/bin/sh

# If MODE is dev, exit right away
if [ "$MODE" = "dev" ]; then
  echo "Will not try to obtain certificates in dev mode."
  exit 0
fi

# ================================================
# == Check if the environment variables are set ==
# ================================================

# Retrieve the domains from an environment variable, space-separated (POSIX compliant).
# Domains should be formed like this: "domain1,sub1.domain1,sub2.domain1 domain2 domain3,sub1.domain3".
# If empty exit with error.
if [ -z "$DOMAINS" ]; then
  echo "DOMAINS environment variable is required" >&2
  exit 1
fi

# Email address for notifications, if empty exit with error
if [ -z "$EMAIL" ]; then
  echo "EMAIL environment variable is required" >&2
  exit 1
fi

# =========================
# == Obtain certificates ==
# =========================

# Function to handle certificate issuance or renewal
obtain_certificate() {
  _domain="${1}"
  cert_path="/etc/letsencrypt/live/$_domain"

  if [ ! -d "$cert_path" ]; then
    # No certificate, obtain one
    echo "No certificate found for $_domain, obtaining one..."
    # obtain using webroot plugin
    certbot certonly \
      --webroot \
      -w /acme-challenge \
      -d "$_domain" \
      --email "$EMAIL" \
      --agree-tos \
      --no-eff-email --dry-run
    echo "Certificate obtained for $_domain."
  fi
}

# Main loop to renew certificates every 24 hours
for domain in $DOMAINS; do
  obtain_certificate "$domain"
done
