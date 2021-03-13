#!/bin/bash

#0: ensure certs dir exists
mkdir -p certs

#1: generate kubernetes CA

#1.1 create kubernetes-ca private key
openssl	genrsa -out certs/kubernetes-ca.key 4096

#1.3 create auto signed certificate
openssl req -new -x509 -days 365 -key certs/kubernetes-ca.key -out certs/kubernetes-ca.crt -config ssl_config/ssl.conf

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
  -out certs/admin.csr \
  -config ssl_config/ssl.conf

#2.3 sign admin certificate
openssl x509 -req -days 365 -sha256 -CA certs/kubernetes-ca.crt -CAkey certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/admin.csr -out certs/admin.crt -extfile ssl_config/ssl.conf


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
   -subj "/C=BR/ST/L=None/O=system:nodes/CN=kube-node" \
   -key certs/$worker.key \
   -out certs/$worker.csr \
   -config ssl_config/ssl.conf

done
  	

#3.3: sign workers certificates
for worker in worker-01 worker-02 worker-03; do
  openssl x509 -req \
    -days 365 \
	-extfile ssl_config/$worker-ssl.conf \
    -sha256 \
    -CA certs/kubernetes-ca.crt \
    -CAkey certs/kubernetes-ca.key \
    -set_serial 01 \
    -extensions req_ext \
    -in certs/$worker.csr \
    -out certs/$worker.crt

    ip=$(echo "$ip+10" | bc);

done


#4.1: generate kube-controller-manager private key
openssl	genrsa -out certs/kube-controller-manager.key 4096

#4.2: generate certificate sign request
openssl req \
  -new \
  -nodes \
  -sha256 \
  -subj "/C=BR/ST=None/L=None/O=None/CN=system:kube-controller-manager" \
  -key certs/kube-controller-manager.key \
  -out certs/kube-controller-manager.csr 

#4.3: sign kube-controller-certificate
openssl x509 \
  -req \
  -days 365 \
  -sha256 \
  -CA certs/kubernetes-ca.crt \
  -CAkey certs/kubernetes-ca.key \
  -set_serial 01 \
  -extensions req_ext \
  -in certs/kube-controller-manager.csr \
  -out certs/kube-controller-manager.crt

#5.1: generate kube proxy private key
openssl genrsa -out certs/kube-proxy.key 4096

#5.2: generate certificate sign request
openssl req \
  -new \
  -nodes \
  -sha256 \
  -subj "/C=BR/ST=None/L=None/O=None/CN=system:kube-proxy" \
  -key certs/kube-proxy.key \
  -out certs/kube-proxy.csr

#5.3: sign kube-proxy certificate
openssl x509 \
  -req \
  -days 365 \
  -sha256 \
  -CA certs/kubernetes-ca.crt \
  -CAkey certs/kubernetes-ca.key \
  -set_serial 01 \
  -extensions req_ext \
  -in certs/kube-proxy.csr \
  -out certs/kube-proxy.crt

#6.1: generate kube-scheduler private key
openssl genrsa -out certs/kube-scheduler.key 4096

#6.2: generate sign certificate request
openssl req \
  -new \
  -nodes \
  -sha256 \
  -subj "/C=BR/ST=None/L=None/O=None/CN=system:kube-scheduler" \
  -key certs/kube-scheduler.key \
  -out certs/kube-scheduler.csr

#6.3 sign kube-scheduler certificate
openssl x509 \
 -req \
 -days 365 \
 -sha256 \
 -CA certs/kubernetes-ca.crt \
 -CAkey certs/kubernetes-ca.key \
 -set_serial 01 \
 -extensions req_ext \
 -in certs/kube-scheduler.csr \
 -out certs/kube-scheduler.crt


echo kubeapi-server
#7.1 generate kube-apiserver private key
openssl genrsa -out certs/kube-apiserver.key 4096

#7.2 generate certificate sign request
openssl req \
  -new \
  -nodes \
  -sha256 \
  -subj "/CN=system:kube-apiserver" \
  -key certs/kube-apiserver.key \
  -out certs/kube-apiserver.csr \
  -config ssl_config/kube-apiserver-ssl.conf


#7.3 sign kube-apiserver certificate
openssl x509 \
	   	-req \
	   	-days 365 \
	  	-extfile ssl_config/kube-apiserver-ssl.conf \
	   	-extensions v3_req \
		-sha256 \
	   	-CA certs/kubernetes-ca.crt \
	   	-CAkey certs/kubernetes-ca.key \
	   	-set_serial 01 \
	   	-in certs/kube-apiserver.csr \
	   	-out certs/kube-apiserver.crt


#8.1: generate service account private key
openssl genrsa -out certs/service-account.key 4096

#8.2: generate certificate sign request
openssl req \
  -new \
  -nodes \
  -sha256 \
  -subj "/C=BR/ST=None/L=None/O=None/CN=service-accounts" \
  -key certs/service-account.key \
  -out certs/service-account.csr

#8.3 sign service account certificate
openssl x509 \
  -req \
  -days 365 \
  -CA certs/kubernetes-ca.crt \
  -CAkey certs/kubernetes-ca.key \
  -set_serial 01 \
  -extensions req_ext \
  -in certs/service-account.csr \
  -out certs/service-account.crt
  

#9.1: generate etcd private key
openssl genrsa -out certs/etcd.key 4096

#9.2: generate certificate sign request
openssl req \
  -new \
  -nodes \
  -sha256 \
  -subj "/CN=etcd-server" \
  -key certs/etcd.key \
  -out certs/etcd.csr \
  -config  ssl_config/etcd-ssl.conf

#9.3: sign etcd certificate 
openssl x509 \
  -req \
  -days 365 \
  -CA certs/kubernetes-ca.crt \
  -CAkey certs/kubernetes-ca.key \
  -set_serial 01 \
  -extensions v3_req \
  -extfile ssl_config/etcd-ssl.conf \
  -in certs/etcd.csr \
  -out certs/etcd.crt 
