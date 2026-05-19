#!/bin/bash
set -e

NODES=("$@")

if [ ${#NODES[@]} -eq 0 ]; then
  echo "Usage: $0 <node1> [node2 ...]"
  exit 1
fi

echo ">>> Gathering node IP addresses..."
HOSTS_BLOCK=""
for node in "${NODES[@]}"; do
  # Get IP of the node (wait up to 5 seconds if needed)
  IP=""
  for i in {1..5}; do
    IP=$(orb run -m "$node" hostname -I 2>/dev/null | awk '{print $1}')
    if [ -n "$IP" ]; then
      break
    fi
    sleep 1
  done

  if [ -z "$IP" ]; then
    echo "Error: Could not retrieve IP for node: $node"
    exit 1
  fi
  echo "Found IP for $node: $IP"
  HOSTS_BLOCK="${HOSTS_BLOCK}${IP} ${node}\n"
done

# Format hosts block
FORMATTED_BLOCK=$(printf "$HOSTS_BLOCK")

# Update /etc/hosts on all nodes
for node in "${NODES[@]}"; do
  echo "Configuring host resolution on $node..."
  # Read existing /etc/hosts, remove any existing JUNG-K8S-LAB block, and append the new one
  orb run -m "$node" sudo bash -c "
    TEMP_FILE=\$(mktemp)
    sed '/# >>> JUNG-K8S-LAB BEGIN >>>/,/# <<< JUNG-K8S-LAB END <<</d' /etc/hosts > \"\$TEMP_FILE\"
    cat \"\$TEMP_FILE\" > /etc/hosts
    rm -f \"\$TEMP_FILE\"
    
    cat <<EOF >> /etc/hosts

# >>> JUNG-K8S-LAB BEGIN >>>
$FORMATTED_BLOCK
# <<< JUNG-K8S-LAB END <<<
EOF
  "
done

echo ">>> Hostname resolution successfully configured across all nodes."
