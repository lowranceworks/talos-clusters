# Talos Cluster Configuration

Encrypted Talos Kubernetes cluster configurations managed with [SOPS](https://github.com/getsops/sops).

## Repository Structure

```
proxmox-homelab/{org}/{team}/{lifecycle}/{purpose}-cluster/
```

**Example:**
- `proxmox-homelab/lowranceworks/personal/prod/personal-cluster/`
- `proxmox-homelab/lawnops/platform/prod/platform-cluster/`
- `proxmox-homelab/lawnops/swe/dev/lawnops-cluster/`

**Full directory tree:**

```
.
├── Taskfile.yaml
├── docs/
│   ├── CREATE_NEW_CLUSTER.md
│   └── UPGRADE_CLUSTER.md
└── proxmox-homelab/
    ├── lawnops/
    │   ├── platform/
    │   │   └── prod/
    │   │       └── platform-cluster/
    │   │           ├── .env
    │   │           ├── .envrc
    │   │           ├── controlplane-01.patch.yaml
    │   │           ├── worker-01.patch.yaml
    │   │           ├── worker-02.patch.yaml
    │   │           └── worker-03.patch.yaml
    │   └── swe/
    │       └── dev/
    │           └── lawnops-cluster/
    │               ├── .env
    │               ├── .envrc
    │               ├── controlplane-01.patch.yaml
    │               ├── worker-01.patch.yaml
    │               ├── worker-02.patch.yaml
    │               └── worker-03.patch.yaml
    └── lowranceworks/
        └── personal/
            └── prod/
                └── personal-cluster/
                    ├── .env
                    ├── .envrc
                    ├── controlplane-01.patch.yaml
                    ├── worker-01.patch.yaml
                    ├── worker-02.patch.yaml
                    └── worker-03.patch.yaml
```

> Encrypted files (`controlplane.yaml`, `worker.yaml`, `kubeconfig`, `talosconfig`, `secrets.yaml`, `tailscale.patch.yaml`) are gitignored and only committed in their encrypted form (`.enc.yaml`, `.enc`). They will appear in the cluster directories after running `task decrypt:all`.

**Directory components:**
- `proxmox-homelab` - Infrastructure provider / homelab root
- `org` - Github Organization (lowranceworks, lawnops)
- `team` - Team/department (platform, swe, personal)
- `lifecycle` - Environment (prod, dev, staging)
- `purpose` - Cluster name/purpose

## Quick Start

### Prerequisites

- [Task](https://taskfile.dev/)
- [SOPS](https://github.com/getsops/sops)
- [talosctl](https://www.talos.dev/)
- GPG key matching `.sops.yaml`

### Basic Workflow

```bash
# Decrypt files for local work
task decrypt:all

# Re-encrypt before committing
task encrypt:all

# Commit encrypted files
git add .
git commit -m "Update configuration"
git push
```

### Applying Configuration

```sh
# Change directory to respective cluster (direnv will read .env to source the kubeconfig context)
cd ./proxmox-homelab/lawnops/platform/prod/platform-cluster/

# Apply the updated configuration to each node
talosctl apply-config \
  --nodes $CONTROLPLANE_01_IP \
  --file controlplane.yaml \
  --config-patch @controlplane-01.patch.yaml \
  --config-patch @tailscale.patch.yaml

talosctl apply-config \
  --file worker.yaml \
  --nodes $WORKER_01_IP \
  --config-patch @worker-01.patch.yaml \
  --config-patch @tailscale.patch.yaml

talosctl apply-config \
  --file worker.yaml \
  --nodes $WORKER_02_IP \
  --config-patch @worker-02.patch.yaml \
  --config-patch @tailscale.patch.yaml

talosctl apply-config \
  --file worker.yaml \
  --nodes $WORKER_03_IP \
  --config-patch @worker-03.patch.yaml \
  --config-patch @tailscale.patch.yaml

talosctl apply-config \
  --file worker.yaml \
  --nodes $WORKER_01_IP \
  --config-patch @worker-01.patch.yaml \
  --config-patch @tailscale.patch.yaml

talosctl apply-config \
  --file worker.yaml \
  --nodes $WORKER_02_IP \
  --config-patch @worker-02.patch.yaml \
  --config-patch @tailscale.patch.yaml

talosctl apply-config \
  --file worker.yaml \
  --nodes $WORKER_03_IP \
  --config-patch @worker-03.patch.yaml \
  --config-patch @tailscale.patch.yaml
```

## Common Commands

| Command | Description |
|---------|-------------|
| `task encrypt:all` | Encrypt all sensitive files across all clusters |
| `task decrypt:all` | Decrypt all `.enc` files across all clusters |
| `task status` | Check encryption status of all clusters |
| `task validate` | Verify all encrypted files can be decrypted |
| `task clean:decrypted` | Remove all decrypted files across all clusters |

## File Naming

- **Decrypted (local only)**: `controlplane.yaml`, `worker.yaml`, `kubeconfig`, `talosconfig`, `secrets.yaml`, `tailscale.patch.yaml`
- **Encrypted (committed)**: `controlplane.enc.yaml`, `worker.enc.yaml`, `kubeconfig.enc`, `talosconfig.enc`, `secrets.enc.yaml`, `tailscale.patch.enc.yaml`
- **Always committed**: `.env`, `.envrc`, `*-controlplane-*.patch.yaml`, `*-worker-*.patch.yaml`

## Security

✅ **Committed:** `*.enc.yaml`, `*.enc` (encrypted files only)  
❌ **Ignored:** Decrypted files (via `.gitignore`)

## Resources

- [SOPS Documentation](https://github.com/getsops/sops)
- [Talos Documentation](https://www.talos.dev/)
- [Task Documentation](https://taskfile.dev/)
