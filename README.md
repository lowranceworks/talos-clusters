# Talos Cluster Configuration

Encrypted Talos Kubernetes cluster configurations managed with [SOPS](https://github.com/getsops/sops).

## Repository Structure

```
clusters/{team}/{lifecycle}/{provider}/{region}/{purpose}-cluster/
```

**Example:**
- `clusters/platform/prod/proxmox/home/platform-cluster/`
- `clusters/swe/dev/proxmox/home/lawnops-cluster/`

**Directory components:**
- `team` - Team/department (platform, swe, data)
- `lifecycle` - Environment (prod, dev, staging)
- `provider` - Infrastructure provider (proxmox, aws, gcp)
- `region` - Location (home, us-east-1, eu-west-1)
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

# Make your changes
vim controlplane-01.yaml

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
cd ./clusters/platform/prod/proxmox/home/platform-cluster/

# Apply the updated configuration to each node
talosctl apply-config --nodes $CONTROLPLANE_01_IP --file controlplane-01.yaml
talosctl apply-config --nodes $WORKER_01_IP --file worker-01.yaml
talosctl apply-config --nodes $WORKER_02_IP --file worker-02.yaml
talosctl apply-config --nodes $WORKER_03_IP --file worker-03.yaml
```

## Common Commands

| Command | Description |
|---------|-------------|
| `task encrypt:all` | Encrypt all files (creates `.enc.yaml` and `.enc` files) |
| `task decrypt:all` | Decrypt all files (removes encrypted versions) |
| `task encrypt:file FILE=path` | Encrypt a specific file |
| `task decrypt:file FILE=path` | Decrypt a specific file |
| `task edit FILE=path` | Edit encrypted file with SOPS |
| `task status` | Check encryption status |
| `task validate` | Verify all encrypted files |
| `task clean:decrypted` | Remove decrypted files |

## File Naming

- **Decrypted (local only)**: `worker-01.yaml`, `kubeconfig`, `.env`
- **Encrypted (committed)**: `worker-01.enc.yaml`, `kubeconfig.enc`, `.env.enc`

## Security

✅ **Committed:** `*.enc.yaml`, `*.enc` (encrypted files only)  
❌ **Ignored:** Decrypted files (via `.gitignore`)

## Resources

- [SOPS Documentation](https://github.com/getsops/sops)
- [Talos Documentation](https://www.talos.dev/)
- [Task Documentation](https://taskfile.dev/)
