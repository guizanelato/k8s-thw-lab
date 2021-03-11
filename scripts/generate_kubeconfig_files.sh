set -euo pipefail

#0: ensure dir exists
mkdir -p kubeconfig

#1: generate worker kubeconfig files 

for instance in worker-01 worker-02 worker-03; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=certs/kubernetes-ca.key \
    --embed-certs=true \
    --server=https://172.20.12.100:6443 \
    --kubeconfig=kubeconfig/${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate="certs/${instance}.crt" \
    --client-key="certs/${instance}.key" \
    --embed-certs=true \
    --kubeconfig="kubeconfig/${instance}.kubeconfig"

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${instance} \
    --kubeconfig="kubeconfig/${instance}.kubeconfig"

  kubectl config use-context default --kubeconfig="kubeconfig/${instance}.kubeconfig"
done


#2: generate kube-proxy kubeconfig

kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=certs/kubernetes-ca.crt \
    --embed-certs=true \
    --server=https://172.20.12.100:6443 \
    --kubeconfig=kubeconfig/kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
    --client-certificate=certs/kube-proxy.crt \
    --client-key=certs/kube-proxy.key\
    --embed-certs=true \
    --kubeconfig=kubeconfig/kube-proxy.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kubeconfig/kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kubeconfig/kube-proxy.kubeconfig

#3: generate kube-controller-manager configuration file

kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=certs/kubernetes-ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kubeconfig/kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=certs/kube-controller-manager.crt \
    --client-key=certs/kube-controller-manager.key \
    --embed-certs=true \
    --kubeconfig=kubeconfig/kube-controller-manager.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kubeconfig/kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kubeconfig/kube-controller-manager.kubeconfig

#4: generate kube-scheduler kubeconfig

kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=certs/kubernetes-ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kubeconfig/kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
    --client-certificate=certs/kube-scheduler.crt \
    --client-key=certs/kube-scheduler.key \
    --embed-certs=true \
    --kubeconfig=kubeconfig/kube-scheduler.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kubeconfig/kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kubeconfig/kube-scheduler.kubeconfig


#5: generate kube-admin kubeconfig

kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=certs/kubernetes-ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kubeconfig/admin.kubeconfig

kubectl config set-credentials admin \
    --client-certificate=certs/admin.crt \
    --client-key=certs/admin.key \
    --embed-certs=true \
    --kubeconfig=kubeconfig/admin.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=kubeconfig/admin.kubeconfig

kubectl config use-context default --kubeconfig=kubeconfig/admin.kubeconfig
