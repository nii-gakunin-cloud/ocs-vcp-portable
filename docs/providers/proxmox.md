# ポータブル版VCPのセットアップ手順 (for proxmox)

## 0. 概要

1. [ネットワーク設定](#nw)
1. [仮想マシンテンプレート作成](#machine)
1. [qemu-agentを利用するための設定](#qemu-agent)
1. [Potable VCコントローラ & Jupyterセットアップ](#vcc-setup)


## 1. ネットワーク設定 <a id="nw"></a>

VCP用の仮想ネットワークを作成します。  
既に存在している設定を利用しても構いません。  
[公式の手順](https://pve.proxmox.com/wiki/Setup_Simple_Zone_With_SNAT_and_DHCP)等を参照し、ネットワーク設定を行ってください。  
ここで設定した情報のうち、VCPで起動したマシンが利用するNICを後ほど指定します。（`vpn_catalog.yml`）

## 2. 仮想マシンテンプレート作成 <a id="machine"></a>

Ubuntu仮想マシンテンプレートを作成します。ここで作成したテンプレートはVCコントローラの他、VCノード構築にも利用します。  
既にテンプレートが作成済みの場合、スキップしてください。  

以下はUbuntu24.04 LTS イメージを利用してテンプレートを作成するスクリプト例です。  
proxmoxのコンソール等で実行することで仮想マシンテンプレート`vcp-ubuntu24`が作成されます。  
[公式のテンプレート作成手順](https://pve.proxmox.com/wiki/Cloud-Init_Support)を参考に適宜パラメータ等を変更してください。（id: `9000` が利用中であれば変更するなど）  

注: このテンプレートをcloneした仮想マシンのディスクサイズは、テンプレートに設定したもの以上でなければ、マシンが正常に利用できない可能性があります。テンプレートのディスクサイズは可能な限り小さくしておくことを推奨します。

```
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img && \
qm create 9000 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci && \
qm set 9000 --name vcp-ubuntu24 && \
qm set 9000 --scsi0 local-lvm:0,import-from=/root/noble-server-cloudimg-amd64.img && \
qm set 9000 --ide2 local-lvm:cloudinit && \
qm set 9000 --boot order=scsi0 && \
qm resize 9000 scsi0 20G && \
qm set 9000 --serial0 socket --vga serial0
qm template 9000
```

## 3. qemu-agentを利用するための設定 <a id="qemu-agent"></a>

VCPにて、マシン起動時に静的IPアドレスを設定しない場合（DHCPを利用してIPアドレスを設定する場合）、起動したマシンのIPアドレスを知るため、qemu-agentを利用します。  
これは、Proxmoxに予めcloud-init用設定ファイルを配置しておき、マシン起動時に反映させることで都度インストールするよう設定します。  
以下をproxmoxのコンソールにて実行することで、vcpで利用する設定ファイル（`/var/lib/vz/snippets/qemu-guest-agent-vcp.yml`）が作成できます。  
利用するマシンテンプレートで予めインストール済みの場合は、内容を変更してください。  

```
cat <<'EOF' > /var/lib/vz/snippets/qemu-guest-agent-vcp.yml
#cloud-config
package_update: false
package_upgrade: false
package_reboot_if_required: false
runcmd:
  - apt-get update && apt-get install -y ca-certificates qemu-guest-agent
  - systemctl restart qemu-guest-agent
  - systemctl enable qemu-guest-agent
EOF
```

## 4. Potable VCコントローラ& Jupyterセットアップ <a id="vcc-setup"></a>

### 仮想マシン作成

先に作成した仮想マシンテンプレートをクローンして仮想マシンを作成します。  
ブラウザ等のGUIから操作を行うか、コンソールから実行してください。  

★ cliで実行する例

```
qm clone 9000 500 --name pvcc --full true
qm set 500 --memory 4096
qm resize 500 scsi0 40G
qm set 500 --sshkey ~/.ssh/id_rsa.pub
qm set 500 --ipconfig0 ip={{付与するipアドレス}},gw={{デフォルトゲートウェイ}}
qm start 500
```

次に、[クイックスタート](../quickstart.md)に従って、構築作業を進めてください。  
