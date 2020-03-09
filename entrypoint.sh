#!/bin/sh
set -e

export EASYRSA_REQ_CN=`hostname`

if [ "$(id -u)" -ne 0 ]; then
    sed -e "s/^nginx:x:[^:]*:[^:]*:/nginx:x:$(id -u):$(id -g):/" /etc/passwd > /tmp/passwd
    cat /tmp/passwd > /etc/passwd
    rm /tmp/passwd
    mkdir -p "$HOME" /tmp/nginx
fi

if [ ! -f "/var/cache/nginx/pki/openssl-easyrsa.cnf" ]; then
    echo "Initiating PKI..."
    easyrsa init-pki
    echo "No OpensslConfig for EasyRsa Found. Copying default configs over..."
    sed "s/RANDFILE/#RANDFILE/g" /usr/share/easy-rsa/openssl-easyrsa.cnf > /var/cache/nginx/pki/openssl-easyrsa.cnf
    cp -R /usr/share/easy-rsa/x509-types /var/cache/nginx/pki/x509-types
    echo "Creating CA using ENV variables..."
    env | grep EASYRSA
    echo -en "\n\n\n\n\n\n\n" | easyrsa build-ca nopass
    echo "Creating CSR..."
    echo -en "\n\n\n\n\n\n\n" | easyrsa gen-req "$EASYRSA_REQ_CN"-req nopass
    echo "Importing request..."
    easyrsa import-req /var/cache/nginx/pki/reqs/"$EASYRSA_REQ_CN"-req.req "$EASYRSA_REQ_CN"-sig
    echo "Signing request..."
    echo -en "yes" | easyrsa sign-req client "$EASYRSA_REQ_CN"-sig
    echo "Setting TLS key and certificates in NGINX config file..."
    sed -i "s@<CERT-FILE>@$EASYRSA_PKI/issued/$EASYRSA_REQ_CN-sig.crt@" /etc/nginx/nginx.conf
    sed -i "s@<CERT-KEY>@$EASYRSA_PKI/private/$EASYRSA_REQ_CN-req.key@" /etc/nginx/nginx.conf
fi

nginx_config_file=/etc/nginx/nginx.conf

WHITELIST_CIDRS=${WHITELIST_CIDRS:-""}

sed -i -e "s_allow    all;_${rules}_" $nginx_config_file
sed -i -e "s/localhost:8082/${BACKEND_SERVER}:${BACKEND_SERVER_PORT}/" $nginx_config_file

exec "$@"