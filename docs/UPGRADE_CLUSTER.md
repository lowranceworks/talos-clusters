# Upgrade Cluster

This guide covers upgrading a Talos cluster from `v1.9.5` to `v1.12.0` using a factory image with extensions.

## Overview

Talos requires upgrading one minor version at a time. The upgrade path is:

`v1.9.5` → `v1.10.6` → `v1.11.3` → `v1.12.0`

Always upgrade control plane nodes before workers, and wait for each phase to complete before proceeding to the next.

## Prerequisites

See [prerequisites](https://github.com/lowranceworks/talos-clusters?tab=readme-ov-file#prerequisites) in the README.

## Factory Image

We use a [Talos Factory](https://factory.talos.dev/) image that bundles the following system extensions:

- `iscsi-tools`
- `qemu-guest-agent`
- `tailscale`
- `util-linux-tools`

Image reference (the tag determines the Talos version):

```
factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:<version>
```

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

- Workers can be upgraded in parallel within the same minor version step.
- Workload disruption is expected during worker upgrades as pods are rescheduled.
- The `install.image` in machine configs should reference the factory image so future `apply-config` operations preserve extensions.

## Troubleshooting

Check kernel logs on a node:

```bash
talosctl logs -n <node-ip> -k
```

Check the boot/upgrade messages:

```bash
talosctl dmesg -n <node-ip>
```
