# Create New Cluster

**Find an available IP address**

```stdout
 ping 192.168.1.122

PING 192.168.1.122 (192.168.1.122): 56 data bytes
Request timeout for icmp_seq 0
Request timeout for icmp_seq 1
```

**Create configs with that IP address**

```sh
export IP_ADDRESS=192.168.1.122
mkdir -p ./clusters/swe/dev/proxmox/home/lawnops-cluster/
cd ./clusters/swe/dev/proxmox/home/lawnops-cluster/

# Generate new cluster secrets
talosctl gen secrets -o secrets.yaml

# Generate configs for new cluster
talosctl gen config \
        dev-proxmox-home-lawnops-cluster \
        https://$IP_ADDRESS:6443 \
        --with-secrets secrets.yaml \
        --output-types controlplane,worker \
        --output .
```

**Apply configuration to the controlPlane**

```sh
pending...
```


**Apply configuration to the workers**

```sh
pending...
```

**Generate config files**

```sh
pending...
```

**Update certSANs, network, gatewayIp, DNS**

```sh
pending...
```

**Encrypt and commit files**

```sh
git checkout -b add-new-cluster
task encrypt:all
git add -A
git commit -m 'feat: add new cluster'
git push --set-upstream origin (git rev-parse --abbrev-ref HEAD)
```
