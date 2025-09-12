# ポータブル版VCPのセットアップ手順 (for proxmox)

## 0. 概要

1. [ネットワーク設定](#ネットワーク設定)
1. [仮想マシンテンプレート作成](#仮想マシンテンプレート作成)
1. [qemu-agentを利用するための設定](#qemu-agentを利用するための設定)
1. [Potable VCコントローラ& Jupyterセットアップ](#PotableVCコントローラJupyterセットアップ)
1. [VCP SDK初期設定](#VCPSDK初期設定)
1. [動作確認](#動作確認)

## 1. ネットワーク設定

VCP用の仮想ネットワークを作成します。  
既に存在している設定を利用しても構いません。  
[公式の手順](https://pve.proxmox.com/wiki/Setup_Simple_Zone_With_SNAT_and_DHCP)等を参照し、ネットワーク設定を行ってください。  
ここで設定した情報のうち、VCPで起動したマシンが利用するNICを後ほど指定します。（`vpn_catalog.yml`）

## 2. 仮想マシンテンプレート作成

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

## 3. qemu-agentを利用するための設定  

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

## 4. Potable VCコントローラ& Jupyterセットアップ

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

### 仮想マシン上で、Portable VCCセットアップ・スクリプトを実行

仮想マシンにログインし、以下の手順でPortable VCCとjupyterのセットアップを行ってください。  

ポータブル版VCコントローラセットアップ用リポジトリをダウンロード  

```
git clone https://github.com/nii-gakunin-cloud/ocs-vcp-portable.git
```

ダウンロードしたディレクトリに移動

```
cd ocs-vcp-portable
```

設定ファイル（`config/vpn_catalog.yml`）を編集します。  
各項目を環境に合わせて設定してください。  

```
cci_version: '1.0'
proxmox:
    default:
        proxmox_pm_api_url: << proxmoxのAPIエンドポイントのURL eg. http://192.168.3.39:8006/api2/json >>
        proxmox_bridge: << VCコントローラで起動した仮想マシンの接続先ブリッジ名 eg. vmbr0 >>
        proxmox_ipv4_gateway: << VCコントローラで起動した仮想マシンのデフォルトゲートウェイ eg. 192.168.3.1 >>
        proxmox_target_node: << proxmoxにて、VCコントローラで起動した仮想マシンを配置するノード eg. vmconsole >>
        proxmox_template_virtual_machine_name: << clone元の仮想マシンテンプレート名 eg. vcp-ubuntu24 >>
        proxmox_storage: << proxmoxにて、VCコントローラで起動した仮想マシンが利用するストレージ名 eg. local-lvm >>
        private_network_ipmask: << VCコントローラで起動する仮想マシンのIPアドレス範囲 eg. 192.168.3.0/24 >>
        proxmox_pm_tls_insecure: << (Optional: default=False) proxmoxサーバへの接続時、tls接続の検証を行わない >>
        pm_parallel: << (Optional: default=1) 同時実行可能数 eg. 2 （複数の仮想マシンを同時に起動する場合などに、その数より小さい値を設定していると、idの競合が起き得る） >>
```

設定ファイル（`config/nginx.conf`）を編集します。  
初期状態では、jupyterサーバへのアクセスをプロキシする設定になっていないため、80番ポートを利用する場合などは設定を変更してください。  
設定例はファイル内に記載しています。（コメントアウト状態）  

```
# jupyterにhttp://{ipaddr or fqdn}/jupyter でアクセスするための設定例
# server {
#     listen 80;
#     server_name localhost;

#     location /jupyter/ {
#         proxy_pass http://localhost:8888/jupyter/;
#         proxy_http_version 1.1;
#         proxy_set_header Upgrade $http_upgrade;
#         proxy_set_header Connection "upgrade";
#         proxy_set_header Host $http_host;
#         proxy_set_header Origin http://$http_host;
#     }
# }
```

VCコントローラを起動します。  
プライベートIPアドレスが付与されているインターフェース名(`ip`コマンド等で確認)を引数に指定してください。  

```
sudo bash init_pvcc.sh <Network IF Name>
```

セットアップ・スクリプトにより以下のインストール、設定等が行われます。  

- Docker CE, Docker Composeインストール
- VCコントローラのコンテナイメージ取得、起動
- VCコントローラの初期設定
- Jupyter Notebookサーバのコンテナイメージ取得、起動

正常終了すると、`ocs-vcp-portable`配下に以下が出力されます。  

- `cred/tokenrc`: VCP REST API アクセストークン
- `cred/jupyter_pass`: jupyterログイン用パスワード

### (オプション)Jupyterログイン用パスワード変更  

Jupyterログイン用パスワードを変更する場合、以下を実行してください。

```
sudo docker exec -ti cloudop-notebook-25.04.0-jupyter-8888 /opt/conda/bin/jupyter notebook password
```

パスワード変更プロンプトが表示されるので、新しいパスワードを入力してください。  
入力している内容は、画面上は表示されません。入力が完了したらEnterを押してください。  
パスワードは、確認用を含めて2度入力する必要があります。  

```
Enter password: <パスワードを入力（1回目）>
```
```
Verify password: <パスワードを入力（2回目）>
```

jupyterコンテナを再起動することで新しいパスワードを有効化します。  

```
sudo docker restart cloudop-notebook-25.04.0-jupyter-8888
```

## 5. VCP SDK初期設定

マシン上に起動したJupyter Notebookで、VCP SDKの初期設定を行います。  
jupyterにアクセスし、`.jupyter_pass`に記載された、もしくは自身で変更したパスワードを用いてログインしてください。  
ログインできたら、ディレクトリにある`SETUP.ipynb`を利用してセットアップを行ってください。  

なお、 `vcp_config/vcp_config.yml` の vcc.host には `127.0.0.1` を記述してください。  

```
vcc:
    host: 127.0.0.1
    name: pvcc
```

## 6. 動作確認

`SETUP.ipynb`実行過程で、`sdk_test`がディレクトリに追加されます。  
その中の`papermill/50_exec_server-proxmox.ipynb`に簡単なVCノード起動例を記載しています。
