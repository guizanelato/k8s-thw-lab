#!/bin/bash

K8S_VERSION=1.20.1
INTERNAL_IP=$(hostname -I | cut -d" " -f2)

#1: create kubernetes configuration directory
sudo mkdir -p /etc/kubernetes/config


#2: download and install k8s 

wget -q --show-progress --https-only --timestamping \
		"https://dl.k8s.io/v$K8S_VERSION/bin/linux/amd64/kube-apiserver" \
		"https://dl.k8s.io/v$K8S_VERSION/bin/linux/amd64/kube-controller-manager" \
		"https://dl.k8s.io/v$K8S_VERSION/bin/linux/amd64/kube-scheduler" \
		"https://dl.k8s.io/v$K8S_VERSION/bin/linux/amd64/kubectl" 

sudo chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/


#3: configure kubernetes api server

sudo mkdir -p /var/lib/kubernetes/

sudo mv kubernetes-ca.crt kubernetes-ca.key kube-apiserver.key  kube-apiserver.crt \
  service-account.key service-account.crt \
  encryption-config.yaml /var/lib/kubernetes/

#3: create systemd service file for kube-apiserver 

cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \
  --advertise-address=${INTERNAL_IP} \
  --allow-privileged=true \
  --apiserver-count=3 \
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path=/var/log/audit.log \
  --authorization-mode=Node,RBAC \
  --bind-address=0.0.0.0 \
  --client-ca-file=/var/lib/kubernetes/kubernetes-ca.crt \
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
  --etcd-cafile=/var/lib/kubernetes/kubernetes-ca.crt \
  --etcd-certfile=/var/lib/kubernetes/kube-apiserver.crt \
  --etcd-keyfile=/var/lib/kubernetes/kube-apiserver.key \
  --etcd-servers=https://172.20.12.10:2379,https://172.20.12.20:2379,https://172.10.20.30:2379 \
  --event-ttl=1h \
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \
  --kubelet-certificate-authority=/var/lib/kubernetes/kubernetes-ca.crt \
  --kubelet-client-certificate=/var/lib/kubernetes/kube-apiserver.crt \
  --kubelet-client-key=/var/lib/kubernetes/kube-apiserver.key \
  --kubelet-https=true \
  --runtime-config='api/all=true' \
  --service-account-key-file=/var/lib/kubernetes/service-account.key \
  --service-cluster-ip-range=172.20.12.0/24 \
  --service-node-port-range=30000-32767 \
  --tls-cert-file=/var/lib/kubernetes/kube-apiserver.crt \
  --tls-private-key-file=/var/lib/kubernetes/kube-apiserver.key \
  --service-account-signing-key-file=/var/lib/kubernetes/service-account.key \
  --service-account-issuer=api \

  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

#4: configure k8s controller manager

sudo mv  kube-controller-manager.kubeconfig /var/lib/kubernetes/


#5: create kube controller systemd service file

cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --bind-address=0.0.0.0 \\
  --cluster-cidr=172.20.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/kubernetes-ca.crt \\
  --cluster-signing-key-file=/var/lib/kubernetes/kubernetes-ca \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/kubernetes-ca.crt \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account.key \\
  --service-cluster-ip-range=172.20.12.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF


#6: configure kube scheduler

sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/

#7: create kube-scheduler yaml

cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1beta1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF


#8: create kube-scheduler.service

cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF


#9: start controller services

sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler

#10: enable http health checks

#10.1: install nginx 
sudo apt update && sudo apt install -y nginx

#10.2 create nginx config

cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF

#10.3 move and create symlink for nginx config file

sudo mv kubernetes.default.svc.cluster.local \
   /etc/nginx/sites-available/kubernetes.default.svc.cluster.local

sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/

#10.4: restart and enable service

sudo systemctl restart nginx
suso systemctl enable nginx

