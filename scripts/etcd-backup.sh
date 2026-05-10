#!/bin/bash
# Script to practice Etcd Backup (Common CKA task)
# Must be run on the Control Plane node

BACKUP_FILE="/tmp/etcd-snapshot-$(date +%Y%m%d%H%M).db"

echo ">>> Performing Etcd Snapshot..."
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save ${BACKUP_FILE}

echo ">>> Backup saved to: ${BACKUP_FILE}"
echo ">>> To verify the backup:"
echo "sudo ETCDCTL_API=3 etcdctl --write-out=table snapshot status ${BACKUP_FILE}"
