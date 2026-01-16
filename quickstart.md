# ポータブル版VCコントローラ（Portable VC Controller: PVCC）起動マニュアル

## 目次

1. [Potable VCコントローラ & Jupyterセットアップ](#PotableVCコントローラJupyterセットアップ)
1. [VCP SDK初期設定](#VCPSDK初期設定)
1. [動作確認](#動作確認)

## 1. Potable VCコントローラ & Jupyterセットアップ

### 仮想マシン作成

ポータブル版VCコントローラと、それを利用するためのJupyterコンテナを１つの仮想マシン上に起動します。  
そのため、仮想マシンを１つ作成してください。

### 仮想マシン上で、Potable VCコントローラセットアップ・スクリプトを実行

仮想マシンにログインし、以下の手順でPotable VCコントローラとjupyterのセットアップを行ってください。  

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

eg1. Proxmoxの設定内容 

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
        pm_parallel: << (Optional: default=1) 同時実行可能数 eg. 2 >>
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
プライベートIPアドレスが付与されているネットワークインターフェース名(`ip`コマンド等で確認)を引数に指定してください。  

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

## 2. VCP SDK初期設定

マシン上に起動したJupyter Notebookで、VCP SDKの初期設定を行います。  
jupyterにアクセスし、`.jupyter_pass`に記載された、もしくは自身で変更したパスワードを用いてログインしてください。  
ログイン後、ディレクトリにある`SETUP.ipynb`を利用してセットアップを行ってください。  

なお、 `vcp_config/vcp_config.yml` の vcc.host には `127.0.0.1` を記述してください。  

```
vcc:
    host: 127.0.0.1
    name: pvcc
```

## 3. 動作確認

`SETUP.ipynb`実行過程で、`sdk_test`がディレクトリに追加されます。  
その中に、プロバイダ毎のVCノード起動例を記載したノートブックがあります。