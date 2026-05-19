#!/bin/bash
set -e

# Define nodes
EXAM1_NODES=("control1" "control2" "control3" "worker1" "worker2")
EXAM1_MASTERS=("control1" "control2" "control3")

# 1. Ensure the base pre-baked image exists
bash scripts/prepare-base.sh

# Reset sander-cka repository to discard any previous host-side modifications
if [ -d "sander-cka" ]; then
  echo ">>> Resetting CKA repository to pristine defaults..."
  (cd sander-cka && git checkout -- .)
fi

echo ">>> Instantly provisioning Exam 1 cluster nodes via OrbStack clones..."
for node in "${EXAM1_NODES[@]}"; do
  # Delete existing container if it is present to guarantee a fresh, clean state
  if orb list | grep -q "${node}"; then
    echo "Deleting existing machine ${node}..."
    orb delete -f "${node}" 2>/dev/null || true
  fi
  
  echo "Cloning ${node} from 'exam1-base'..."
  orb clone exam1-base "${node}"
  orb start "${node}"
done

echo ">>> Configuring dynamic hostname resolution..."
bash scripts/setup-hosts.sh "${EXAM1_NODES[@]}"

echo ">>> Preparing Load Balancer configurations (Keepalived & HAProxy)..."

CONTROL1_IP=$(orb run -m control1 hostname -I | awk '{print $1}')
CONTROL2_IP=$(orb run -m control2 hostname -I | awk '{print $1}')
CONTROL3_IP=$(orb run -m control3 hostname -I | awk '{print $1}')
echo ">>> Resolved IPs: control1=${CONTROL1_IP}, control2=${CONTROL2_IP}, control3=${CONTROL3_IP}"

# Dynamically calculate Virtual IP (VIP) compatible with the dynamic OrbStack subnet
SUBNET_PREFIX=$(echo $CONTROL1_IP | cut -d. -f1-3)
VIP="${SUBNET_PREFIX}.200"
echo ">>> Dynamic Virtual IP for Load Balancer: ${VIP}"

# Patch config files with correct dynamic VIP and node IPs
perl -pi -e "s/interface ens33/interface eth0/g" sander-cka/keepalived.conf
perl -pi -e "s/192.168.29.100/${VIP}/g" sander-cka/keepalived.conf
perl -pi -e "s/192.168.29.100/${VIP}/g" sander-cka/check_apiserver.sh

perl -pi -e "s/server control1.*/server control1 ${CONTROL1_IP}:6443 check/g" sander-cka/haproxy.cfg
perl -pi -e "s/server control2.*/server control2 ${CONTROL2_IP}:6443 check/g" sander-cka/haproxy.cfg
perl -pi -e "s/server control3.*/server control3 ${CONTROL3_IP}:6443 check/g" sander-cka/haproxy.cfg

# Generate site-specific keepalived configs for control2 and control3
cp sander-cka/keepalived.conf sander-cka/keepalived-control2.conf
cp sander-cka/keepalived.conf sander-cka/keepalived-control3.conf

perl -pi -e 's/state MASTER/state SLAVE/g' sander-cka/keepalived-control2.conf
perl -pi -e 's/state MASTER/state SLAVE/g' sander-cka/keepalived-control3.conf
perl -pi -e 's/priority 255/priority 254/g' sander-cka/keepalived-control2.conf
perl -pi -e 's/priority 255/priority 253/g' sander-cka/keepalived-control3.conf

# 2. Set up passwordless SSH between all masters
echo ">>> Setting up passwordless SSH keys between control plane nodes..."
# Generate SSH key on control1 if it doesn't exist
orb run -m control1 bash -c '[ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa'
PUB_KEY=$(orb run -m control1 bash -c 'cat ~/.ssh/id_rsa.pub')

# Authorize the key on all masters to allow passwordless ssh
for node in "${EXAM1_MASTERS[@]}"; do
  echo "Authorizing control1 SSH key on ${node}..."
  echo "$PUB_KEY" | orb run -m "$node" bash -c '
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    read KEY
    if ! grep -q "$KEY" ~/.ssh/authorized_keys 2>/dev/null; then
      echo "$KEY" >> ~/.ssh/authorized_keys
    fi
    chmod 600 ~/.ssh/authorized_keys
  '
done

echo ">>> Installing haproxy and keepalived on all 3 control plane nodes..."
for node in "${EXAM1_MASTERS[@]}"; do
  echo "Installing packages on ${node}..."
  orb run -m "$node" sudo useradd -r -s /sbin/nologin -M keepalived_script || true
  orb run -m "$node" sudo apt-get install -y haproxy keepalived
done

echo ">>> Distributing check_apiserver.sh to all control plane nodes..."
for node in "${EXAM1_MASTERS[@]}"; do
  orb run -m "$node" sudo mkdir -p /etc/keepalived
  orb run -m "$node" sudo cp sander-cka/check_apiserver.sh /etc/keepalived/check_apiserver.sh
  orb run -m "$node" sudo chmod +x /etc/keepalived/check_apiserver.sh
done

echo ">>> Distributing Keepalived and HAProxy configs to all control plane nodes..."
# Copy keepalived configs
orb run -m control1 sudo cp sander-cka/keepalived.conf /etc/keepalived/keepalived.conf
orb run -m control2 sudo cp sander-cka/keepalived-control2.conf /etc/keepalived/keepalived.conf
orb run -m control3 sudo cp sander-cka/keepalived-control3.conf /etc/keepalived/keepalived.conf

# Copy haproxy configs
for node in "${EXAM1_MASTERS[@]}"; do
  orb run -m "$node" sudo mkdir -p /etc/haproxy
  orb run -m "$node" sudo cp sander-cka/haproxy.cfg /etc/haproxy/haproxy.cfg
done

# Enable and restart services on all masters
echo ">>> Starting and enabling keepalived and haproxy services..."
for node in "${EXAM1_MASTERS[@]}"; do
  echo "Enabling services on ${node}..."
  orb run -m "$node" sudo systemctl enable keepalived --now
  orb run -m "$node" sudo systemctl enable haproxy --now
  orb run -m "$node" sudo systemctl restart keepalived
  orb run -m "$node" sudo systemctl restart haproxy
done

echo ">>> All Sander van Vugt CKA scripts (CRI, kubetools, load balancer) successfully executed!"
