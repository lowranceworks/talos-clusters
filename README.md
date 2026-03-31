# Talos Cluster Configuration

Encrypted Talos Kubernetes cluster configurations managed with [SOPS](https://github.com/getsops/sops).

## Repository Structure

```
proxmox-homelab/{org}/{lifecycle}/{purpose}-cluster/
```

**Example:**
- `proxmox-homelab/lowranceworks/personal/prod/`
- `proxmox-homelab/lawnops/prod/platform-cluster/`
- `proxmox-homelab/lawnops/dev/lawnops-cluster/`

**Full directory tree:**

```
.
├── Taskfile.yaml
├── docs/
│   ├── CREATE_NEW_CLUSTER.md
│   └── UPGRADE_CLUSTER.md
└── proxmox-homelab/
    ├── lawnops/
    │   ├── dev/
    │   │   └── lawnops-cluster/
    │   │       ├── .env
    │   │       ├── .envrc
    │   │       ├── controlplane-01.patch.yaml
    │   │       ├── worker-01.patch.yaml
    │   │       ├── worker-02.patch.yaml
    │   │       └── worker-03.patch.yaml
    │   └── prod/
    │       └── platform-cluster/
    │           ├── .env
    │           ├── .envrc
    │           ├── controlplane-01.patch.yaml
    │           ├── worker-01.patch.yaml
    │           ├── worker-02.patch.yaml
    │           └── worker-03.patch.yaml
    └── lowranceworks/
        └── personal/
            └── prod/
                ├── .env
                ├── .envrc
                ├── controlplane-01.patch.yaml
                ├── worker-01.patch.yaml
                ├── worker-02.patch.yaml
                └── worker-03.patch.yaml
```

> Encrypted files (`controlplane.yaml`, `worker.yaml`, `secrets.yaml`) are gitignored and only committed in their encrypted form (`.enc.yaml`). They will appear in the cluster directories after running `task decrypt:all`.

**Directory components:**
- `proxmox-homelab` - Infrastructure provider / homelab root
- `org` - Github Organization (lowranceworks, lawnops)
- `lifecycle` - Environment (prod, dev, staging)
- `purpose` - Cluster name/purpose (omitted when org path is sufficient)

## Quick Start

### Prerequisites

- [Task](https://taskfile.dev/)
- [SOPS](https://github.com/getsops/sops)
- [talosctl](https://www.talos.dev/)
- GPG key at `~/.keys/sops/local` (fingerprint: `46A08BAEF7DB948F66897A69C6D12C69DB830D3B`)

To import the key on a new machine:

```bash
gpg --import ~/.keys/sops/local
```

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
cd ./proxmox-homelab/lawnops/prod/platform-cluster/

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

- **Decrypted (local only)**: `controlplane.yaml`, `worker.yaml`, `secrets.yaml`
- **Encrypted (committed)**: `controlplane.enc.yaml`, `worker.enc.yaml`, `secrets.enc.yaml`
- **Always committed**: `.env`, `.envrc`, `controlplane-*.patch.yaml`, `worker-*.patch.yaml`

## Security

✅ **Committed:** `*.enc.yaml`, `*.enc` (encrypted files only)  
❌ **Ignored:** Decrypted files (via `.gitignore`)

## Resources

- [SOPS Documentation](https://github.com/getsops/sops)
- [Talos Documentation](https://www.talos.dev/)
- [Task Documentation](https://taskfile.dev/)
