# Talos Cluster Upgrade Guide

This guide covers upgrading the Talos cluster from v1.9.5 to v1.12.0 with factory image extensions.

## Overview

Talos requires upgrading one minor version at a time. Our upgrade path:
- v1.9.5 → v1.10.6 → v1.11.3 → v1.12.0

## Prerequisites

- Use [direnv]() and `.env` to set environment variables for node IPs:
```bash
  CONTROLPLANE_01_IP=192.168.1.150
  WORKER_01_IP=192.168.1.151
  WORKER_02_IP=192.168.1.152
  WORKER_03_IP=192.168.1.153
```

- Factory image with extensions:
```
  factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2
```
  
  Includes: iscsi-tools, qemu-guest-agent, tailscale, util-linux-tools

## Upgrade Process

### Step 1: Upgrade Control Plane to v1.10.6
```bash
talosctl upgrade -n $CONTROLPLANE_01_IP \
  --image factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:v1.10.6
```

Wait for completion. Verify:
```bash
talosctl version -n $CONTROLPLANE_01_IP
```

### Step 2: Upgrade Control Plane to v1.11.3
```bash
talosctl upgrade -n $CONTROLPLANE_01_IP \
  --image factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:v1.11.3
```

Wait for completion.

### Step 3: Upgrade Control Plane to v1.12.0
```bash
talosctl upgrade -n $CONTROLPLANE_01_IP \
  --image factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:v1.12.0
```

Wait for completion.

### Step 4: Upgrade All Workers to v1.10.6
```bash
talosctl upgrade -n $WORKER_01_IP --image factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:v1.10.6
talosctl upgrade -n $WORKER_02_IP --image factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:v1.10.6
talosctl upgrade -n $WORKER_03_IP --image factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:v1.10.6
```

Wait for all workers to complete.

### Step 5: Upgrade All Workers to v1.11.3
```bash
talosctl upgrade -n $WORKER_01_IP --image factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:v1.11.3
talosctl upgrade -n $WORKER_02_IP --image factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:v1.11.3
talosctl upgrade -n $WORKER_03_IP --image factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:v1.11.3
```

Wait for all workers to complete.

### Step 6: Upgrade All Workers to v1.12.0
```bash
talosctl upgrade -n $WORKER_01_IP --image factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:v1.12.0
talosctl upgrade -n $WORKER_02_IP --image factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:v1.12.0
talosctl upgrade -n $WORKER_03_IP --image factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:v1.12.0
```

Wait for all workers to complete.

## Verification

### Check Cluster Version
```bash
talosctl version -n $CONTROLPLANE_01_IP
```

Expected output: `Tag: v1.12.0`

### Verify Extensions Installed
```bash
talosctl get extensions -n $CONTROLPLANE_01_IP
talosctl get extensions -n $WORKER_01_IP
talosctl get extensions -n $WORKER_02_IP
talosctl get extensions -n $WORKER_03_IP
```

Expected extensions:
- iscsi-tools
- qemu-guest-agent
- tailscale
- util-linux-tools

### Check Cluster Health
```bash
kubectl get nodes
kubectl get pods -A
```

## Notes

- Always upgrade control planes before workers
- Wait for each upgrade phase to complete before proceeding
- Workers can be upgraded simultaneously
- Workload disruption is expected during worker upgrades as pods are rescheduled
- The `install.image` in machine configs has been updated to use the factory image for future operations

## Troubleshooting

If an upgrade fails:
```bash
talosctl logs -n <node-ip> -k
```

To check upgrade status:
```bash
talosctl dmesg -n <node-ip>
```
