# syntax=docker/dockerfile:1

##############################################
FROM nginxinc/nginx-unprivileged:stable-alpine
##############################################

# For convenience
USER root
ARG nonroot=nginx

##############################################
# Preparing
##############################################

VOLUME [ "/etc/letsencrypt", "/var/lib/letsencrypt", "/acme-challenge" ]
EXPOSE 80

# Install Certbot
RUN apk add --no-cache certbot openssl

RUN mkdir -p /etc/letsencrypt ; \
    chown -R $nonroot:$nonroot /etc/letsencrypt
RUN mkdir -p /var/lib/letsencrypt ; \
    chown -R $nonroot:$nonroot /var/lib/letsencrypt
RUN mkdir -p /var/log/letsencrypt ; \
    chown -R $nonroot:$nonroot /var/log/letsencrypt

# Webroot available for Certbot and Nginx
RUN mkdir -p /acme-challenge ; \
    chown -R $nonroot:$nonroot /acme-challenge ; \
    chmod -R 755 /acme-challenge

COPY scripts /scripts
RUN chmod +x /scripts/*.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY conf.d/ /etc/nginx/conf.d/
RUN chown -R $nonroot:$nonroot /etc/nginx/conf.d/

##############################################
# Main
##############################################

# Switch to nginx and run
USER $nonroot
ENTRYPOINT [ "/entrypoint.sh" ]
