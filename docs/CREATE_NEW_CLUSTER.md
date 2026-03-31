# Create New Cluster

## Create Virtual Servers

I do this through [Proxmox]().

## Configuration Steps

### Preperation for configuration

**Define where your configuration will live**

I've decided to organize my directory structure like this:

```
proxmox-homelab/{org}/{lifecycle}/{purpose}-cluster/
```

```stdout
.
└── proxmox-homelab
    ├── lawnops
    │   ├── dev
    │   │   └── lawnops-cluster
    │   └── prod
    │       └── platform-cluster
    └── lowranceworks
        └── prod
            └── personal-cluster
```

I've already created the directory structure, I will change into this directory:

```sh
cd ./proxmox-homelab/lowranceworks/personal/prod
```

**Find available IP addresses on your network**

I prefer static IP addresses that I can group together sequentially.

```stdout
 ping 192.168.1.140

PING 192.168.1.140 (192.168.1.140): 56 data bytes
Request timeout for icmp_seq 0
Request timeout for icmp_seq 1
```

```stdout
 ping 192.168.1.141

PING 192.168.1.141 (192.168.1.141): 56 data bytes
Request timeout for icmp_seq 0
Request timeout for icmp_seq 1
```

```stdout
 ping 192.168.1.142

PING 192.168.1.142 (192.168.1.142): 56 data bytes
Request timeout for icmp_seq 0
Request timeout for icmp_seq 1

```
```stdout
 ping 192.168.1.143

PING 192.168.1.143 (192.168.1.143): 56 data bytes
Request timeout for icmp_seq 0
Request timeout for icmp_seq 1
```

**Generate Tailscale API key**

Create a free account with [Tailscale](https://tailscale.com) if you don't already have one.

Review their documentation on [how to create an API key](https://tailscale.com/kb/1085/auth-keys).

Once you've created one, save the key because we will need it later.

> **Note:** The auth key is only valid for a maximum of 90 days. This does not mean your nodes will be removed from the Tailnet after 90 days — it only means the key can no longer be used to add new nodes. You'll need to generate a new one at that point.

### Writing the configuration

**Define Environment Variables**

I prefer to record these in a `.env` file. The `.envrc` loads the `.env` file but can also be used to run commands when you change directory or reload with `direnv reload`.

```sh
touch .env
touch .envrc && echo "dotenv .env" >> .envrc
direnv allow
```

**Write the current IP addresses assigned to the nodes to `.env`**

You can expect these to change later -- it's good idea to document here so we can run the same commands.

```stdout
CONTROLPLANE_01_IP=192.168.1.117
KUBECONFIG=./kubeconfig
TALOSCONFIG=./talosconfig
WORKER_01_IP=192.168.1.98
WORKER_02_IP=192.168.1.104
WORKER_03_IP=192.168.1.242
```

Why `KUBECONFIG`? Setting this tells `kubectl` where to find the cluster credentials. By pointing it to a local `./kubeconfig` file, you avoid polluting your global `~/.kube/config` and can work with multiple clusters by simply changing directories.

Why `TALOSCONFIG`? Same idea — `talosctl` looks for this environment variable to find its configuration. Keeping it scoped to the cluster directory means each cluster's `talosconfig` stays isolated and you don't have to pass `--talosconfig` on every command.

**Load environment variables**

You need to allow `direnv` to work in your current directory.

```sh
direnv allow
```

After doing this, you can verify if your environment variables are loaded into your shell:

```sh
env | grep $TALOSCONFIG
env | grep $KUBECONFIG
env | grep $CONTROLPLANE_01_IP
env | grep $WORKER_01_IP
env | grep $WORKER_02_IP
env | grep $WORKER_03_IP
```

**Generate configuration files:**

```sh
talosctl gen config personal-cluster https://$CONTROLPLANE_01_IP:6443 --output-dir .
```

**Create patch file for control-plane:**

`controlplane-01.patch.yaml`:

```sh
touch controlplane-01.patch.yaml
```

**Declare configuration for control-plane:**

```yaml
machine:
    # Static IP Configuration
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

**Create patch files for each worker:**

```sh
touch worker-01.patch.yaml
touch worker-02.patch.yaml
touch worker-03.patch.yaml
```

**Update the patch files for each worker:**

`worker-01.patch.yaml`:

```yaml
machine:
    # Static IP Configuration
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
    # Mounts Required for Longhorn on Worker Nodes
    # Remove This Section for Control Plane Nodes!
    # (Leave for Single Node Cluster)
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

**Create tailscale.patch.yaml file**

This patch is shared across all nodes. It writes a Tailscale auth environment file that the Tailscale system extension reads on boot to register the node with your Tailnet.

```sh
touch tailscale.patch.yaml
```

`tailscale.patch.yaml`:

```yaml
apiVersion: v1alpha1
kind: ExtensionServiceConfig
name: tailscale
environment:
  - TS_AUTHKEY=tskey-auth-your-authkey-here
```

Replace `tskey-auth-your-authkey-here` with the auth key you generated earlier.

> **Tip:** If you want each node to have a recognizable hostname in your Tailnet, you can add `TS_EXTRA_ARGS=--advertise-tags=tag:kubernetes --hostname=personal-cp-01` and create per-node Tailscale patches instead. For simplicity, a single shared patch works — Tailscale will use the machine's hostname by default.

### Apply configuration to nodes

**Now you can apply the configurations to each node**

```sh
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

### Bootstrap the cluster

After applying the configuration, the nodes will reboot and their IPs and hostnames will change to the static values you defined in the patch files. Update your `.env` file with the new static IPs:

```stdout
CONTROLPLANE_01_IP=192.168.1.140
WORKER_01_IP=192.168.1.141
WORKER_02_IP=192.168.1.142
WORKER_03_IP=192.168.1.143
```

Reload your environment:

```sh
direnv reload
```

**Bootstrap etcd on the first control plane node**

This only needs to be done once, on the first control plane node:

```sh
talosctl bootstrap \
  --nodes $CONTROLPLANE_01_IP \
  --endpoints $CONTROLPLANE_01_IP
```

**Retrieve the kubeconfig**

```sh
talosctl kubeconfig \
  --nodes $CONTROLPLANE_01_IP \
  --endpoints $CONTROLPLANE_01_IP \
  -f .
```

This writes the `kubeconfig` file to the current directory. Since `KUBECONFIG` is already set to `./kubeconfig`, `kubectl` will pick it up automatically.

### Verify cluster health

**Check that all nodes are ready:**

```sh
kubectl get nodes -o wide
```

You should see your control plane and all worker nodes in `Ready` status.

**Check Talos services:**

```sh
talosctl health \
  --nodes $CONTROLPLANE_01_IP \
  --endpoints $CONTROLPLANE_01_IP
```

**Verify Tailscale is running on nodes:**

```sh
talosctl -n $CONTROLPLANE_01_IP services | grep tailscale
```

The nodes should also appear in your [Tailscale admin console](https://login.tailscale.com/admin/machines).

**Check system pods are running:**

```sh
kubectl get pods -A
```

All system pods (coredns, kube-apiserver, kube-scheduler, etc.) should be in `Running` or `Completed` status.

### Encrypt and commit files

```sh
git checkout -b create-cluster
task encrypt:all
git add -A
git commit -m 'feat: add new cluster'
git push --set-upstream origin (git rev-parse --abbrev-ref HEAD)
```
