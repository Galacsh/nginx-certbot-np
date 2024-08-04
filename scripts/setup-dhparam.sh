#!/bin/sh

# If MODE is not prod, exit right away
if [ "$MODE" != "prod" ]; then
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

# =========================
# == Obtain certificates ==
# =========================

# ssl_dhparam.pem for a secure configuration
setup_ssl_dhparam() {
  comma_seperated_domains="${1}"
  base_domain=$(echo "${comma_seperated_domains}" | cut -d ',' -f1)
  cert_path="/etc/letsencrypt/live/${base_domain}"

  mkdir -p "${cert_path}"

  if [ ! -f "${cert_path}/ssl-dhparam.pem" ]; then
    echo "Generating ssl-dhparam.pem file..."
    openssl dhparam -out "$cert_path/ssl-dhparam.pem" 2048
    echo "Generated ${cert_path}/ssl-dhparam.pem file."
  fi
}

# ==============================

for domain in $DOMAINS; do
  setup_ssl_dhparam "$domain"
done
