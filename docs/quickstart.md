# ポータブル版VCコントローラ（Portable VC Controller: PVCC）起動マニュアル

## 目次

1. [Potable VCコントローラ & Jupyterセットアップ](#vcc-setup)
1. [VCP SDK初期設定](#setup-vcpsdk)
1. [動作確認](#check-operation)

## 1. Potable VCコントローラ & Jupyterセットアップ <a id="vcc-setup"></a>

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
利用するクラウドプロバイダに応じた設定を行ってください。  

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

正常終了すると、画面上に以下が出力されます。**再表示できないため、必ず控えてください。**  

- jupyterログイン用パスワード
- VCP REST API アクセストークン

`http://<ip addr>:8888/jupyter` でアクセスし、控えておいたjupyterログイン用パスワードでログインしてください。  
※ 受け付けるポート番号等は、Nginx設定ファイル（`config/nginx.conf`）で設定変更可能です。  
※ ファイヤーウォール等の設定は各利用環境に応じたものを別途行ってください。

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

## 2. VCP SDK初期設定 <a id="setup-vcpsdk"></a>

マシン上に起動したJupyter Notebookで、VCP SDKの初期設定を行います。  
Jupyterにログイン後、ディレクトリにある`SETUP.ipynb`を利用してセットアップを行ってください。  

なお、 `vcp_config/vcp_config.yml` の vcc.host には `127.0.0.1` を記述してください。  

```
vcc:
    host: 127.0.0.1
    name: pvcc
```

## 3. 動作確認 <a id="check-operation"></a>

`SETUP.ipynb`実行過程で、`sdk_test`がディレクトリに追加されます。  
その中に、プロバイダ毎のVCノード起動例を記載したノートブックがあります。