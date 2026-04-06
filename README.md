# Talos Cluster Configuration

Encrypted Talos Kubernetes cluster configurations managed with [SOPS](https://github.com/getsops/sops).

## Repository Structure

```
proxmox-homelab/{org}/{lifecycle}/{purpose}-cluster/
```

```
.
├── .gitignore
├── .sops.yaml
├── README.md
├── Taskfile.yaml
├── docs/
│   ├── CREATE_NEW_CLUSTER.md
│   └── UPGRADE_CLUSTER.md
└── proxmox-homelab/
    ├── lawnops/
    │   ├── dev/
    │   │   └── lawnops-cluster/
    │   └── prod/
    │       └── platform-cluster/
    └── lowranceworks/
        └── prod/
            └── personal-cluster/
```

**Directory path convention:** `proxmox-homelab/{org}/{lifecycle}/{purpose}-cluster/`

- `proxmox-homelab` -- Infrastructure provider / homelab root
- `org` -- GitHub organization (`lowranceworks`, `lawnops`)
- `lifecycle` -- Environment (`prod`, `dev`, `staging`)
- `purpose` -- Cluster name/purpose

### Cluster directory files

Each cluster directory contains the following files:

| File | Committed | Description |
|------|-----------|-------------|
| `.env` | Yes | Environment variables (node IPs, config paths) |
| `.envrc` | Yes | Loads `.env` via direnv |
| `controlplane-*.patch.yaml` | Yes | Control plane node patches (hostname, static IP) |
| `worker-*.patch.yaml` | Yes | Worker node patches (hostname, static IP, mounts) |
| `controlplane.enc.yaml` | Yes | Encrypted control plane machine config |
| `worker.enc.yaml` | Yes | Encrypted worker machine config |
| `secrets.enc.yaml` | Yes | Encrypted cluster secrets bundle |
| `tailscale.patch.enc.yaml` | Yes | Encrypted Tailscale auth key patch |
| `kubeconfig.enc` | Yes | Encrypted Kubernetes client config |
| `talosconfig.enc` | Yes | Encrypted Talos client config |
| `controlplane.yaml` | No | Decrypted control plane config |
| `worker.yaml` | No | Decrypted worker config |
| `secrets.yaml` | No | Decrypted secrets bundle |
| `tailscale.patch.yaml` | No | Decrypted Tailscale patch |
| `kubeconfig` | No | Decrypted Kubernetes client config |
| `talosconfig` | No | Decrypted Talos client config |

> Decrypted files appear locally after running `task decrypt:all` and are removed when running `task encrypt:all`.

## Quick Start

### Prerequisites

- VMs or bare-metal hosts to run Talos on (we use [Proxmox](https://www.proxmox.com/), but any hypervisor or hardware works)
- [Task](https://taskfile.dev/)
- [SOPS](https://github.com/getsops/sops)
- [talosctl](https://www.talos.dev/)
- [direnv](https://direnv.net/)
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

## Security

Sensitive values are encrypted with [SOPS](https://github.com/getsops/sops) using GPG. Only specific YAML keys are encrypted (selective encryption), so non-sensitive fields like hostnames, cluster names, and API server addresses remain readable in the encrypted files.

- `*.enc.yaml` -- YAML files with selective key encryption
- `*.enc` -- Config files (`kubeconfig`, `talosconfig`) with selective key encryption
- Decrypted plaintext files are and never committed

## Resources

- [SOPS Documentation](https://github.com/getsops/sops)
- [Talos Documentation](https://www.talos.dev/)
- [Task Documentation](https://taskfile.dev/)
