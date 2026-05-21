#!/usr/bin/env bash
set -euo pipefail

# Apply Talos configs to all nodes in the current cluster directory.
# Run from a cluster directory (e.g., proxmox-homelab/lowranceworks/dev/app-cluster/)
# where .env is sourced via direnv.
#
# Usage: talos-apply.sh

# Ensure required files exist
for f in worker.yaml controlplane.yaml tailscale.patch.yaml; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: $f not found. Decrypt it first (e.g., sops -d ${f%.yaml}.enc.yaml > $f)" >&2
        exit 1
    fi
done

# Apply worker configs
for patch in worker-*.patch.yaml; do
    num="${patch#worker-}"
    num="${num%.patch.yaml}"
    var="WORKER_${num}_PUBLIC_IP"
    ip="${!var:-}"

    if [[ -z "$ip" ]]; then
        echo "WARNING: $var is not set, skipping $patch" >&2
        continue
    fi

    echo "Applying worker-${num} config to ${ip}..."
    talosctl apply-config \
        --file worker.yaml \
        --nodes "$ip" \
        --config-patch "@${patch}" \
        --config-patch @tailscale.patch.yaml
done

# Apply controlplane configs
for patch in controlplane-*.patch.yaml; do
    num="${patch#controlplane-}"
    num="${num%.patch.yaml}"
    var="CONTROLPLANE_${num}_PUBLIC_IP"
    ip="${!var:-}"

    if [[ -z "$ip" ]]; then
        echo "WARNING: $var is not set, skipping $patch" >&2
        continue
    fi

    echo "Applying controlplane-${num} config to ${ip}..."
    talosctl apply-config \
        --file controlplane.yaml \
        --nodes "$ip" \
        --config-patch "@${patch}" \
        --config-patch @tailscale.patch.yaml
done

echo "Done."
