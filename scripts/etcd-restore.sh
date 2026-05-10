#!/bin/bash
# Template for Etcd Restore practice
# WARNING: This script is destructive and intended for educational purposes on a practice cluster.

BACKUP_FILE=$1
if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 /path/to/backup.db"
    exit 1
fi

DATA_DIR="/var/lib/etcd-restore"

echo ">>> Stopping Kubernetes components..."
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/
sleep 10

echo ">>> Restoring snapshot to ${DATA_DIR}..."
sudo ETCDCTL_API=3 etcdctl \
  snapshot restore ${BACKUP_FILE} \
  --data-dir=${DATA_DIR}

echo ">>> Updating Etcd manifest to use new data-dir..."
# In a real CKA exam, you'd edit /etc/kubernetes/manifests/etcd.yaml 
# to point the hostPath volume 'etcd-data' to the new restore directory.
# For now, we'll just show the command.
echo "Manually update /etc/kubernetes/manifests/etcd.yaml hostPath for etcd-data to: ${DATA_DIR}"

echo ">>> Restarting components..."
sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

echo ">>> Restore process initiated. Check pod status: kubectl get pods -n kube-system"
