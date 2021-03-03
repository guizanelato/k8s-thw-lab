#!/bin/bash

#0: ensure certs dir exists
mkdir -p certs

#1: generate kubernetes CA

#1.1 create kubernetes-ca private key
openssl	genrsa -out certs/kubernetes-ca.key 4096

#1.3 create auto signed certificate
openssl req -new -x509 -days 365 -key certs/kubernetes-ca.key -out certs/kubernetes-ca.crt

#2: generate admin client certificate

#2.1 create admin private-key
openssl genrsa -out certs/admin.key 4096

#2.2 generate certificate sign request
openssl req \
  -new \
  -nodes \
  -sha256 \
  -subj "/C=US/ST=None/L=None/O=system:masters/CN=kubernetes-admin" \
  -key certs/admin.key \
  -out certs/admin.csr

#2.3 sign admin certificate
openssl x509 -req -days 365 -sha256 -CA certs/kubernetes-ca.crt -CAkey certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/admin.csr -out certs/admin.crt


#3: generate worker certificates

#3.1: create workers private keys
for worker in worker-01 worker-02 worker-03; do
  openssl genrsa -out certs/$worker.key
done

#3.2: generate certificate sign requests
ip=60
for worker in worker-01 worker-02 worker-03; do
  openssl req \
   -new \
   -nodes \
   -sha256 \
   -subj "/C=BR/ST/L=None/O=system:nodes/CN=$worker,172.20.12.$ip" \
   -key certs/$worker.key \
   -out certs/$worker.csr;

   ip=$(echo "$ip+10" | bc);
done
  	

#3.3: sign workers certificates
for worker in worker-01 worker-02 worker-03; do
  openssl x509 -req \
    -days 365 \
    -sha256 \
    -CA certs/kubernetes-ca.crt \
    -CAkey certs/kubernetes-ca.key \
    -set_serial 01 \
    -extensions req_ext \
    -in certs/$worker.csr \
    -out certs/$worker.crt 
done
