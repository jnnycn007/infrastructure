# Centrinix Deployment Plan

## Network

### Notes

* All physical servers are connected to two separate Ethernet switches via 10GbE
  or 40GbE ports with 802.3ad operating in active-active mode (aggregated
  bandwidth of 20Gbps or 80Gbps).
* Virtual networks requiring connections to physical devices are defined on VLAN
  for simplicity.
* Strictly virtual networks are defined on VXLAN.
* VXLAN network operates in the "PXSDN" VLAN with OSPF underlay and each PVE
  node operating as a VTEP.
* Switches are not acting as a VXLAN VTEP to simplify configurations and reduce
  potential interoperability issues.
* WAN uplink is available on the "WAN1" VLAN with both static and DHCP IPv4
  allocations.
* Proxmox management traffic is routed on the "PXDMZ" VLAN.
* Proxmox VM migration/replication and storage (mainly NFS and some iSCSI)
  traffic is routed on the "PXSTOR" VLAN.
* Zephyr CI virtual server traffic is routed on the "ZCIDMZ" VXLAN.
* A dedicated firewall/router "zephyr-ci-rt1" is placed on the "ZCIDMZ" VXLAN
  for WAN NAT and inter-subnet routing.
* A remote management VPN, "ZCIDMZVPN", is hosted by "zephyr-ci-rt1" and has
  access to all internal ZCI networks.
* Kubernetes cluster traffic is routed over the "ZCIKUBE1" VLAN.
* "ZCIKUBE1" VLAN, and thereby the containers themselves, has firewall-ed access
  to other ZCI networks via "zephyr-ci-rt1".
* Hardware testing CI device nodes are placed on the "ZCIHWLAB1" VLAN.

### Private Networks

|Name|Type|Tag|IPv4|Description|
|:---:|:---:|:---:|:---:|:---:|
|PXDMZ|VLAN|100|10.32.0.0/16|Proxmox DMZ|
|PXSDN|VLAN|116|10.48.0.0/16|Proxmox SDN|
|PXSTOR|VLAN|132|10.64.0.0/16|Proxmox Storage|
|WAN1|VLAN|900|various|Internet Uplink|
|ZCIDMZ|VXLAN|8190|172.16.214.0/24|Zephyr CI DMZ|
|ZCIKUBE1|VLAN|1670|172.17.132.0/22|Zephyr CI Kubernetes Cluster 1|
|ZCIHWLAB1|VLAN|1680|172.17.136.0/22|Zephyr CI Hardware Lab 1|
|ZCIDMZVPN|-|-|172.16.246.0/24|Zephyr CI DMZ VPN|

### Remote Access

A WireGuard VPN server is set up on the "zephyr-ci-rt1" node for remotely
accessing the private networks, including the "ZCIDMZ" and "ZCIKUBE1" networks
used for deployment host and Kubernetes node SSH access.

The WireGuard VPN operates on the private IPv4 network `172.16.246.0/24` and the
client traffic to the private networks is forwarded by the "zephyr-ci-rt1"
router.

## Storage

### Notes

* Each server has a RAID-ed boot drive that also acts as a local VM storage when
  high availability or fast migration is required.
* The primary VM storage is the Fibre Channel SAN.
* All physical servers are connected to two separate Fibre Channel switches via
  8GFC or 16GFC ports operating in active-active mode (aggregated bandwidth of
  16Gbps or 32Gbps).
* VM storage HDD and SSD volumes are exported by the small "sandisk1" SAN disk
  array (HP P2000 G3).
* The large "sandisk2" SAN disk array (HP 3PAR 7440c) is currently shut down to
  save operating cost; it may be brought back online in the future if there is a
  requirement for very large and high performance HDD array.

### SAN Volumes

|Name|Description|
|:---:|:---:|
|sandisk1-slc1|Primary VM storage with SLC RAID-5 SSDs|
|sandisk1-r10hd1|Secondary VM and data storage with RAID-10 10krpm HDDs|

## Servers

### Notes

* All physical servers run Proxmox Virtual Environment OS (Debian-based).
* The only Arm64 compute node, k1ca1, is an exception and runs Rancher
  Kubernetes Engine directly onthe node without virtualisation because Proxmox
  currently only supports the x86-64 architecture.

### Server List

|Name|Primary FQDN<br />IP Address|Description|
|:---:|:---:|:---:|
|zephyr-ci-rt1|rt1.dmz.zephyr-ci.centrinix.cloud<br />172.16.214.1|Main Firewall/Router|
|zephyr-ci-deploy1|deploy1.dmz.zephyr-ci.centrinix.cloud<br />172.16.214.100|Main Deployment/Management<br />hosts a K3s cluster that runs the Rancher Server|
|zephyr-ci-k1ms1|k1ms1.kube1.zephyr-ci.centrinix.cloud<br />172.17.132.10|Kubernetes Cluster 1 Master 1|
|zephyr-ci-k1ms2|k1ms2.kube1.zephyr-ci.centrinix.cloud<br />172.17.132.11|Kubernetes Cluster 1 Master 2|
|zephyr-ci-k1ms3|k1ms3.kube1.zephyr-ci.centrinix.cloud<br />172.17.132.12|Kubernetes Cluster 1 Master 3|
|zephyr-ci-k1chc1|k1chc1.kube1.zephyr-ci.centrinix.cloud<br />172.17.132.20|Kubernetes Cluster 1 Cache 1|
|zephyr-ci-k1chc2|k1chc2.kube1.zephyr-ci.centrinix.cloud<br />172.17.132.21|Kubernetes Cluster 1 Cache 2|
|zephyr-ci-k1chc3|k1chc3.kube1.zephyr-ci.centrinix.cloud<br />172.17.132.22|Kubernetes Cluster 1 Cache 3|
|zephyr-ci-k1cx1|k1cx1.kube1.zephyr-ci.centrinix.cloud<br />172.17.133.1|Kubernetes Cluster 1 x86 Compute 1|
|zephyr-ci-k1ca1|k1ca1.kube1.zephyr-ci.centrinix.cloud<br />172.17.133.200|Kubernetes Cluster 1 Arm64 Compute 1|

## Software Stack

### Rancher Kubernetes Cluster

* A K3s cluster is deployed on "zephyr-ci-deploy1" to host the Rancher Server.
* 3 master nodes (k1ms1, k1ms2 and k1ms3) are deployed on Proxmox to 3 separate
  physical servers.
* No VM-level high availability is configured for the Kubernetes master nodes in
  Proxmox since provisioning multiple master nodes already ensures fault
  tolerance at Kubernetes cluster level.
* Rancher Server web management interface is available at
  [deploy1.dmz.zephyr-ci.centrinix.cloud](https://deploy1.dmz.zephyr-ci.centrinix.cloud).


### Kubernetes Services

* 3 KeyDB pods are deployed for distributed ccache operation.
* Actions Runner Controller is deployed to orchestrate ephemeral GitHub Actions
  runners in the Kubernetes cluster.

## Deployment Procedure

### Rancher Deployment Node

1. Configure IP networks in the NetworkManager.

    * Configure IP address on the `DMZ` virtual NICs.
    * Ensure that the `DMZ` network is used as the default gateway.

    ```
    IFACE_DMZ=enp6s18
    IP_DMZ=172.16.214.100

    nmcli connection add type ethernet \
      con-name DMZ \
      dev $IFACE_DMZ \
      ipv4.method manual \
      ipv4.addresses $IP_DMZ/24 \
      ipv4.gateway 172.16.214.1 \
      ipv4.dns 172.16.214.1 \
      ipv4.dns-search dmz.zephyr-ci.centrinix.cloud \
      ipv6.method disabled
    ```

1. Install [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) and
   [`helm`](https://helm.sh/docs/intro/install/#from-script).

    ```
    # Download and validate pre-compiled kubectl binary.
    curl -LO https://dl.k8s.io/release/v1.31.5/bin/linux/amd64/kubectl
    curl -LO https://dl.k8s.io/release/v1.31.5/bin/linux/amd64/kubectl.sha256
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

    # Install kubectl binary.
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    # Download and run helm install script.
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    ```

    Note that these commands are to be executed as the root user on the deployment host; hence, the
    default Kubernetes tooling and client context is assumed to be for the K3s installation of the
    K3s instance of the deployment host.

1. [Install K3s Kubernetes cluster.](https://documentation.suse.com/cloudnative/rancher-manager/latest/en/installation-and-upgrade/quick-start/deploy-rancher/helm-cli.html#_install_suse_rancher_prime_k3s_on_linux)

    ```
    # Run K3s installation script.
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.31.5+k3s1 sh -s - server --cluster-init

    # Make K3s client config the user default.
    cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    ```

1. [Deploy Rancher Prime Server on the K3s Kubernetes cluster.](https://documentation.suse.com/cloudnative/rancher-manager/latest/en/installation-and-upgrade/quick-start/deploy-rancher/helm-cli.html#_install_rancher_with_helm)

    ```
    # Add Helm repositories.
    helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
    helm repo add jetstack https://charts.jetstack.io
    helm repo update

    # Install cert-manager for issuing Rancher web UI TLS certificates in the K3s "under-cloud".
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.crds.yaml
    helm install cert-manager \
        jetstack/cert-manager \
        --version v1.17.1 \
        --namespace cert-manager \
        --create-namespace

    # Install Rancher in the K3s "under-cloud".
    kubectl create namespace cattle-system
    helm install rancher \
        rancher-latest/rancher \
        --version v2.10.2 \
        --namespace cattle-system \
        --set hostname=deploy1.dmz.zephyr-ci.centrinix.cloud \
        --set replicas=1 \
        --set bootstrapPassword=<PASSWORD_FOR_RANCHER_ADMIN>
    ```

    Note that:

    * The K3s "under-cloud" deployment is not highly available and is solely
      hosted by the `zephyr-ci-deploy1` host. While it would be nice to make the
      K3s "under-cloud" highly available, this is not strictly necessary
      because, once the CI service Kubernetes cluster is up and running, the
      Rancher Server and its underlying K3s cluster only function as a
      "convenience tool" for managing the cluster. The CI service Kubernetes
      cluster itself shall be deployed in a highly available configuration.

### Rancher Kubernetes Cluster Nodes

> [!NOTE]
> When cloning an existing Rancher Kubernetes node, ensure the following:
>
> 1. Keep the NIC of the cloned node disconnected prior to full
>    re-configuration.
> 1. Configure new node IP and hostname in the NetworkManager (use `nmtui` for
>    convenience).
> 1. Re-generate host SSH key (`rm -f /etc/ssh/ssh_host_*` and `ssh-keygen -A`).
> 1. Uninstall RKE2 (`rke2-uninstall.sh`).
> 1. Stop and disable `rancher-system-agent` service
>    (`rancher-system-agent-uninstall.sh`).
> 1. Purge all Rancher files (`rm -rf /etc/rancher /var/lib/rancher`).
> 1. Reboot.
> 1. Re-connect the NIC.
> 1. Run the new Rancher node provisioning script.

1. Configure IP networks in the NetworkManager.

    * Configure IP address on the `KUBE1` virtual NICs.
    * Ensure that the `KUBE1` network is used as the default gateway.

    ```
    IFACE_KUBE1=ens18
    IP_KUBE1=172.17.133.99

    nmcli connection add type ethernet \
      con-name KUBE1 \
      dev $IFACE_KUBE1 \
      ipv4.method manual \
      ipv4.addresses $IP_KUBE1/22 \
      ipv4.gateway 172.17.132.1 \
      ipv4.dns 172.17.132.1 \
      ipv4.dns-search kube1.zephyr-ci.centrinix.cloud \
      ipv6.method disabled
    ```

1. Install required system packages.

    ```
    # dnsutils for nslookup
    dnf install -y dnsutils

    # tar required by Rancher deployment script
    dnf install -y tar
    ```

1. Run cluster node bootstrap script from Rancher web UI.

## Operations and Management

### Client Configuration

#### WireGuard VPN Client

```
[Interface]
Address = 172.16.246.99/24
DNS = 172.16.246.1
SaveConfig = true
PrivateKey = <REDACTED>

[Peer]
PublicKey = <REDACTED>
AllowedIPs = 172.16.246.0/24, 172.16.214.0/24, 172.17.132.0/22, 172.17.136.0/22
Endpoint = vpn.zephyr-ci.centrinix.cloud:51820
```
