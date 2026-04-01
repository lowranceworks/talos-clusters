# Create New Cluster

## Prerequisites

- [Proxmox](https://www.proxmox.com/) VMs provisioned with the Talos Factory ISO
- [talosctl](https://www.talos.dev/) installed
- [direnv](https://direnv.net/) installed and hooked into your shell
- [Task](https://taskfile.dev/) installed
- [SOPS](https://github.com/getsops/sops) installed with GPG key imported
- A [Tailscale](https://tailscale.com) account and auth key

### Talos Factory Image

Use a Talos Factory image that includes system extensions. Download the ISO from:

```
https://factory.talos.dev/?arch=amd64&extensions=siderolabs%2Ftailscale&version=1.12.0
```

Direct ISO download:

```
https://factory.talos.dev/image/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2/v1.12.0/nocloud-amd64.iso
```

This image includes: iscsi-tools, qemu-guest-agent, tailscale, util-linux-tools.

> **Important:** You must use a factory image that includes the Tailscale extension. If you use the default Talos ISO, the Tailscale service will not be available even if you apply the tailscale patch.

### Tailscale Auth Key

Create an auth key from the [Tailscale admin console](https://login.tailscale.com/admin/settings/keys). The key is used to register nodes with your Tailnet.

> **Note:** Auth keys expire after a maximum of 90 days. This does not remove existing nodes from the Tailnet -- it only means the key can no longer register new nodes.

## Create Virtual Servers

Create VMs in Proxmox using the Talos Factory ISO. Boot each VM and note the DHCP-assigned IP addresses displayed on the console.

## Configuration Steps

### Directory structure

```
proxmox-homelab/{org}/{lifecycle}/{purpose}-cluster/
```

Create the directory for your new cluster and `cd` into it:

```sh
mkdir -p proxmox-homelab/lowranceworks/prod/personal-cluster
cd proxmox-homelab/lowranceworks/prod/personal-cluster
```

### Define environment variables

Create `.env` and `.envrc` files:

```sh
touch .env .envrc
echo 'dotenv .env' >> .envrc
direnv allow
```

Write the DHCP-assigned IPs to `.env` (these will change to static IPs after applying config):

```
TALOSCONFIG=./talosconfig
KUBECONFIG=./kubeconfig
CONTROLPLANE_01_IP=192.168.1.117
WORKER_01_IP=192.168.1.98
WORKER_02_IP=192.168.1.104
WORKER_03_IP=192.168.1.242
```

- `TALOSCONFIG` -- tells `talosctl` where to find its config. Keeps each cluster isolated.
- `KUBECONFIG` -- tells `kubectl` where to find cluster credentials. Avoids polluting `~/.kube/config`.

Verify environment variables are loaded:

```sh
direnv reload
echo $CONTROLPLANE_01_IP $WORKER_01_IP $WORKER_02_IP $WORKER_03_IP
```

### Generate configuration files

```sh
talosctl gen config <cluster-name> https://$CONTROLPLANE_01_IP:6443 --output-dir .
```

This generates: `controlplane.yaml`, `worker.yaml`, `talosconfig`.

#### Set talosconfig endpoints

The generated `talosconfig` has empty endpoints. Set them so you don't need `--endpoints` on every command:

```sh
talosctl config endpoint $CONTROLPLANE_01_IP
```

> **Note:** After applying static IPs, update the endpoint to the new controlplane IP.

### Create patch files

**Control plane patch** (`controlplane-01.patch.yaml`):

```yaml
machine:
    network:
        hostname: personal-cp-01
        interfaces:
            - interface: eth0
              addresses:
                - 192.168.1.140/24
              routes:
                - network: 0.0.0.0/0
                  gateway: 192.168.1.254
              dhcp: false
```

**Worker patches** (`worker-01.patch.yaml`, `worker-02.patch.yaml`, `worker-03.patch.yaml`):

```yaml
machine:
    network:
        hostname: personal-worker-01
        interfaces:
            - interface: eth0
              addresses:
                - 192.168.1.141/24
              routes:
                - network: 0.0.0.0/0
                  gateway: 192.168.1.254
              dhcp: false
    kubelet:
        extraMounts:
            - destination: /var/lib/longhorn
              type: bind
              source: /var/lib/longhorn
              options:
                - bind
                - rshared
                - rw
```

**Tailscale patch** (`tailscale.patch.yaml`):

This patch is shared across all nodes:

```yaml
apiVersion: v1alpha1
kind: ExtensionServiceConfig
name: tailscale
environment:
  - TS_AUTHKEY=tskey-auth-your-authkey-here
```

Replace `tskey-auth-your-authkey-here` with the auth key you generated.

### Apply configuration to nodes

When nodes are freshly booted from the Talos ISO (maintenance mode), use `--insecure` since there is no existing trust relationship. No `--endpoints` flag is needed -- the `--nodes` flag tells `talosctl` where to connect directly.

**Control plane:**

```sh
talosctl apply-config \
  --nodes $CONTROLPLANE_01_IP \
  --file controlplane.yaml \
  --config-patch @controlplane-01.patch.yaml \
  --config-patch @tailscale.patch.yaml \
  --insecure
```

**Workers:**

```sh
talosctl apply-config \
  --nodes $WORKER_01_IP \
  --file worker.yaml \
  --config-patch @worker-01.patch.yaml \
  --config-patch @tailscale.patch.yaml \
  --insecure

talosctl apply-config \
  --nodes $WORKER_02_IP \
  --file worker.yaml \
  --config-patch @worker-02.patch.yaml \
  --config-patch @tailscale.patch.yaml \
  --insecure

talosctl apply-config \
  --nodes $WORKER_03_IP \
  --file worker.yaml \
  --config-patch @worker-03.patch.yaml \
  --config-patch @tailscale.patch.yaml \
  --insecure
```

> **When to use `--insecure`:** Only on first apply to nodes in maintenance mode (fresh boot from ISO). After config is applied and the node reboots, it has a trust relationship with your `talosconfig` and `--insecure` is no longer needed.
>
> **When to use `--endpoints`:** Not needed for initial apply. After bootstrapping, `talosctl` uses the endpoints from your `talosconfig`. For worker commands, the endpoint should point to the controlplane (workers proxy through the controlplane API).

### Update IPs and bootstrap

After applying config, nodes reboot with their new static IPs. Update `.env`:

```
CONTROLPLANE_01_IP=192.168.1.140
WORKER_01_IP=192.168.1.141
WORKER_02_IP=192.168.1.142
WORKER_03_IP=192.168.1.143
```

Reload environment and update talosconfig endpoint:

```sh
direnv reload
talosctl config endpoint $CONTROLPLANE_01_IP
```

**Bootstrap etcd** (only once, on the first control plane node):

```sh
talosctl bootstrap --nodes $CONTROLPLANE_01_IP
```

**Retrieve kubeconfig:**

```sh
talosctl kubeconfig --nodes $CONTROLPLANE_01_IP -f .
```

This writes `kubeconfig` to the current directory. Since `KUBECONFIG=./kubeconfig`, `kubectl` picks it up automatically.

### Verify cluster health

```sh
# Check nodes
kubectl get nodes -o wide

# Check Talos services
talosctl health --nodes $CONTROLPLANE_01_IP

# Verify Tailscale is running
talosctl -n $CONTROLPLANE_01_IP services | grep tailscale

# Check system pods
kubectl get pods -A
```

Nodes should also appear in the [Tailscale admin console](https://login.tailscale.com/admin/machines).

### Save secrets and encrypt

```sh
# Extract secrets bundle from controlplane config
talosctl gen secrets --from-controlplane-config controlplane.yaml

# Encrypt all sensitive files
task encrypt:all

# Commit
git checkout -b create-cluster
git add -A
git commit -m 'feat: add new cluster'
git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)
```

## Applying configuration changes (existing cluster)

After the cluster is bootstrapped, you no longer need `--insecure`. Use the controlplane as the endpoint for all commands:

```sh
# Control plane
talosctl apply-config \
  --nodes $CONTROLPLANE_01_IP \
  --file controlplane.yaml \
  --config-patch @controlplane-01.patch.yaml \
  --config-patch @tailscale.patch.yaml

# Workers (endpoint is the controlplane)
talosctl apply-config \
  --nodes $WORKER_01_IP \
  --endpoints $CONTROLPLANE_01_IP \
  --file worker.yaml \
  --config-patch @worker-01.patch.yaml \
  --config-patch @tailscale.patch.yaml
```

## Troubleshooting

### `error constructing client: failed to determine endpoints`

Your `talosconfig` has no endpoints set. Either set them permanently:

```sh
talosctl config endpoint $CONTROLPLANE_01_IP
```

Or pass `--endpoints` on each command:

```sh
talosctl -n $CONTROLPLANE_01_IP --endpoints $CONTROLPLANE_01_IP services
```

### `tls: certificate signed by unknown authority`

The node's Talos OS CA doesn't match your `talosconfig` client CA. This happens when:
- You regenerated config files but the node still has the old config
- The `talosconfig` was generated separately from the `controlplane.yaml`

**Fix:** If the node hasn't been bootstrapped, apply with `--insecure`:

```sh
talosctl apply-config \
  --nodes $NODE_IP \
  --file controlplane.yaml \
  --config-patch @controlplane-01.patch.yaml \
  --insecure
```

**Fix:** If you need to regenerate a matching `talosconfig` from existing config:

```sh
talosctl gen secrets --from-controlplane-config controlplane.yaml -o secrets.yaml
talosctl gen config <cluster-name> https://$CONTROLPLANE_01_IP:6443 \
  --with-secrets secrets.yaml \
  --output-types talosconfig \
  --output . \
  --force
rm secrets.yaml
```

### `tls: certificate required`

The node is in maintenance mode and requires a direct insecure connection. Do not use `--endpoints`:

```sh
talosctl apply-config \
  --nodes $NODE_IP \
  --file worker.yaml \
  --config-patch @worker-01.patch.yaml \
  --insecure
```

### Tailscale service not running

Verify the Talos Factory image includes the Tailscale extension:

```sh
talosctl get extensions -n $CONTROLPLANE_01_IP
```

If `tailscale` is not listed, the node was installed with a default Talos ISO. You need to either:
- **Reinstall** with the factory ISO that includes Tailscale
- **Upgrade** to the factory image:
  ```sh
  talosctl upgrade -n $NODE_IP \
    --image factory.talos.dev/installer/077514df2c1b6436460bc60faabc976687b16193b8a1290fda4366c69024fec2:v1.12.0
  ```

> **Note:** Talos only supports upgrading one minor version at a time. See [UPGRADE_CLUSTER.md](UPGRADE_CLUSTER.md) for step-by-step instructions.

After the extension is installed, apply the tailscale patch and verify:

```sh
talosctl -n $CONTROLPLANE_01_IP services | grep tailscale
```

### SOPS MAC mismatch

```
MAC mismatch. File has <hash>, computed <hash>
```

This happens when an encrypted file was modified outside of SOPS (e.g., manual edit, merge conflict, line ending changes).

**Fix:** Re-encrypt the file with `--ignore-mac`:

```sh
sops --ignore-mac --decrypt <file>.enc.yaml > <file>.yaml
sops --encrypt <file>.yaml > <file>.enc.yaml
rm <file>.yaml
```

### Environment variables not loading (direnv)

If `direnv` doesn't load `.env` automatically, ensure the hook is installed in your shell:

```sh
# bash
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
source ~/.bashrc

# zsh
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
source ~/.zshrc
```

Then allow the directory:

```sh
direnv allow
```

### GPG key not found (SOPS decryption fails)

If SOPS fails with `No secret key` or `no such file or directory`:

```sh
# Import the GPG keys
gpg --import ~/.keys/sops/local/lowranceworks/sops-public.asc
gpg --import ~/.keys/sops/local/lowranceworks/sops-private.asc

# Verify
gpg --list-secret-keys
```

### Lost kubeconfig or talosconfig

These files are not stored in git (they're gitignored). If lost:

**talosconfig** -- Regenerate from existing cluster secrets:

```sh
talosctl gen secrets --from-controlplane-config controlplane.yaml -o secrets.yaml
talosctl gen config <cluster-name> https://$CONTROLPLANE_01_IP:6443 \
  --with-secrets secrets.yaml \
  --output-types talosconfig \
  --output . \
  --force
talosctl config endpoint $CONTROLPLANE_01_IP
rm secrets.yaml
```

**kubeconfig** -- Fetch from a running cluster (requires working talosconfig):

```sh
talosctl kubeconfig --nodes $CONTROLPLANE_01_IP -f .
```

> **Note:** If connecting over Tailscale, the kubeconfig server address will use the LAN IP. You may need to update it to the Tailscale hostname for remote access:
> ```sh
> # Check the Tailscale hostname of the controlplane
> # Update the server address in kubeconfig to use it
> ```
