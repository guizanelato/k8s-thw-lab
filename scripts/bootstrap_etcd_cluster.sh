#!/bin/bash

ETCD_VERSION=3.4.15

#1: download etcds binaries
wget -q --show-progress --https-only --timestamping \
          "https://github.com/etcd-io/etcd/releases/download/v$ETCD_VERSION/etcd-v$ETCD_VERSION-linux-amd64.tar"

#2: extract and install etcd

tar -xvf etcd-v$ETCD_VERSION-linux-amd64.tar
sudo mv etcd-v$ETCD_VERSION-linux-amd64/etcd* /usr/local/bin/

#3: configure etcd server

sudo mkdir -p /etc/etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd
sudo cp kubernetes-ca.crt kube-apiserver.crt etcd.key etcd.crt /etc/etcd/

#4: gather internal_ip and hostname 
INTERNAL_IP=$(hostname -I | cut -d" " -f2)
ETCD_NAME=$(hostname -s)

#5: create systemd service config file for etcd

cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/etcd.crt \\
  --key-file=/etc/etcd/etcd.key \\
  --peer-cert-file=/etc/etcd/etcd.crt \\
  --peer-key-file=/etc/etcd/etcd.key \\
  --trusted-ca-file=/etc/etcd/kubernetes-ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/kubernetes-ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster manager-01=https://172.20.12.10:2380,manager-02=https://172.20.12.20:2380,manager-03=https://172.20.12.30:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF


# start and enable etcd server

sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd


