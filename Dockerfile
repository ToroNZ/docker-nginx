FROM nginxinc/nginx-unprivileged:stable-alpine

USER root

ENV EASYRSA_CRL_DAYS=3650 \
    EASYRSA_CA_EXPIRE=3650 \
    EASYRSA_CERT_EXPIRE=1095 \
    EASYRSA_PKI=/var/cache/nginx/pki \
    EASYRSA_REQ_COUNTRY="NZ" \
    EASYRSA_REQ_PROVINCE="Wellington" \
    EASYRSA_REQ_CITY="Wellington" \
    EASYRSA_REQ_ORG="Copyleft Ltd" \
    EASYRSA_REQ_EMAIL="webmaster@copyleft.nz" \
    EASYRSA_REQ_OU="Copyleft-OPS" \
    EASYRSA_KEY_SIZE=4096 \
    EASYRSA_ALGO="rsa" \
    EASYRSA_DN="org"

RUN apk add --no-cache easy-rsa bash && \
    mkdir /pki && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/bin/easyrsa

# Make /var/cache/nginx/ writable by non-root users
RUN chgrp -R nginx /var/cache/nginx/ \
    && chmod -R g=u /var/cache/nginx/ \
    && addgroup nginx root \
    && chmod 664 /etc/passwd \
    # nginx user must own the cache directory to write cache
    && chown -R nginx:root /var/cache/nginx \
    # nginx user must be able to read config files
    && chgrp -R 0 /etc/nginx \
    && chmod -R g=u /etc/nginx

# Add files
ADD entrypoint.sh /entrypoint.sh
ADD nginx.conf /etc/nginx/nginx.conf
ADD ssl/ssl.pem /etc/ssl/private/ssl.pem
ADD ssl/ssl.key /etc/ssl/private/ssl.key

EXPOSE 9443
USER nginx

# entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# start nginx
CMD ["nginx", "-g", "daemon off;"]
