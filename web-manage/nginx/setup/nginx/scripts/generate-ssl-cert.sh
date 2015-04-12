#!/bin/sh

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 host.domain"
  echo "eg. $0 www.contegix.com"
   exit 1
fi

HOSTNAME=$1
SERIAL=`date +%Y%m%d%H%M`

umask 077

openssl genrsa -out $HOSTNAME.key 2048
openssl req -new -set_serial $SERIAL -key $HOSTNAME.key -out $HOSTNAME.csr
openssl x509 -set_serial $SERIAL -req -days 3650 -in $HOSTNAME.csr -signkey $HOSTNAME.key -out $HOSTNAME.self.crt
