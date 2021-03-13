
node_names="manager-01 manager-02 manager-03 worker-01 worker-02 worker-03 load-balancer traefik"

read -r -a machines <<< "$node_names"

#0: set target directory & vagrant dir path

#../.vagrant/machines/manager-01/virtualbox/private_key
vagrant_dir="../.vagrant/machines/"
cert_dir="certs"

#1: ensure target directory exists
if [[ ! -d $cert_dir ]] ; then
  echo "Error:  $cert_dir does not exists."
  exit 1
else
	echo "$cert_dir exists."
	echo "Checking machine status"  
fi		

#2: ensure vagrant machines are up
for machine in "${machines[@]}"; do
  $(vagrant status $machine 2>&1 > /dev/null)
  if [[ ! $? -eq 0 ]] ;  then
    echo "$machine is not running - check vagrant status."
	exit 1
  fi 
  echo "$machine is up and running."
done

#3:ensure vagrant-scp is installed
echo "Checking vagrant-scp plugin installation..."

installed=0

for plugin in $(vagrant plugin list); do
  if [[ $plugin -eq "vagrant-scp" ]]; then
	echo "already installed"
	installed=1
	break 
  fi
done

if [[ $installed -eq 0 ]]; then
  vagrant plugin install vagrant-scp
fi

echo "vagrant-scp is installed."


#4: distribute worker certificates and kubeconfig files
for worker in worker-01 worker-02 worker-03; do
	vagrant scp certs/$worker.crt $worker:~/
    vagrant scp certs/kubernetes-ca.crt $worker:~/
	vagrant scp kubeconfig/$worker.kubeconfig $worker:~/
	vagrant scp kubeconfig/kube-proxy.kubeconfig $worker:~/
done

for manager in manager-01 manager-02 manager-03; do
  vagrant scp certs/kubernetes-ca.crt $manager:~/
  vagrant scp certs/kubernetes-ca.key $manager:~/
  vagrant scp certs/service-account.crt $manager:~/
  vagrant scp certs/service-account.key $manager:~/
  vagrant scp certs/kube-apiserver.crt $manager:~/
  vagrant scp certs/kube-apiserver.key $manager:~/
  vagrant scp certs/etcd.crt $manager:~/
  vagrant scp certs/etcd.key $manager:~/
  vagrant scp encryption-config.yaml $manager:~/ 
  vagrant scp bootstrap_etcd_cluster.sh $manager:~/
  vagrant scp kubeconfig/admin.kubeconfig $manager:~/
  vagrant scp kubeconfig/kube-controller-manager.kubeconfig $manager:~/
  vagrant scp kubeconfig/kube-scheduler.kubeconfig $manager:~/

done

