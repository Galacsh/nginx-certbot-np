# syntax=docker/dockerfile:1

##################################################
FROM nginxinc/nginx-unprivileged:stable-alpine3.19
##################################################

# For convenience
EXPOSE 80
EXPOSE 443

VOLUME [ "/etc/letsencrypt", "/var/lib/letsencrypt", "/usr/share/nginx/html" ]

ARG nonroot=nginx

##############################################

# Install Certbot
USER root
RUN apk add --no-cache "certbot" "openssl"

RUN mkdir -p /etc/letsencrypt ; \
  chown -R $nonroot:$nonroot /etc/letsencrypt
RUN mkdir -p /var/lib/letsencrypt ; \
  chown -R $nonroot:$nonroot /var/lib/letsencrypt
RUN mkdir -p /var/log/letsencrypt ; \
  chown -R $nonroot:$nonroot /var/log/letsencrypt

# options-ssl-nginx.conf for a secure configuration
# https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf
COPY --chown=$nonroot:$nonroot ./options-ssl-nginx.conf /etc/letsencrypt/options-ssl-nginx.conf

# Default conf file that does:
#   - HTTP to HTTPS redirection
#   - ACME challenge
COPY --chown=$nonroot:$nonroot ./conf.d/http-default.conf /etc/nginx/conf.d/http-default.conf

# For ACME challenge.
# This directory does not need to be persistent.
RUN mkdir -p /acme-challenge ; \
  chown -R $nonroot:$nonroot /acme-challenge ; \
  chmod -R 755 /acme-challenge

COPY scripts /scripts
RUN chmod +x /scripts/*.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN chown -R $nonroot:$nonroot /etc/nginx/conf.d/

##############################################
# Main
##############################################

# Switch to nginx and run
USER $nonroot
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "nginx", "-g", "daemon off;" ]
