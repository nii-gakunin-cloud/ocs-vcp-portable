# ポータブル版VCPのセットアップ手順 (for proxmox)

## 0. 概要

1. 仮想マシンテンプレートを作成する。
1. Portable VCコントローラ用に仮想マシンを作成する。
1. Potable VCコントローラと同じ仮想マシン上のJupyter NotebookでVCP SDKを設定する。
1. VCノードを既存サーバ(SSH)モードで使用するためのmdx仮想マシンを作成する。
1. OCSテンプレートのNotebookを実行する。

## 1. Portable VCコントローラ用の仮想マシンを作成

- 仮想マシンテンプレートを作成する  

    Ubuntu仮想マシンテンプレートを作成します。ここで作成したテンプレートはVCコントローラの他、VCノード構築にも利用します。  
    既にテンプレートが作成済みの場合、スキップしてください。  

    以下はUbuntu24.04 LTS イメージを利用してテンプレートを作成するスクリプト例です。  
    proxmoxのコンソール等で実行することで仮想マシンテンプレート`vcp-ubuntu24`が作成されます。  
    [公式のテンプレート作成手順](https://pve.proxmox.com/wiki/Cloud-Init_Support)を参考に適宜パラメータ等を変更してください。（id: `9000` が利用中であれば変更するなど）  

    ```
    wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img && \
    qm create 9000 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci && \
    qm set 9000 --name vcp-ubuntu24 && \
    qm set 9000 --scsi0 local-lvm:0,import-from=/root/noble-server-cloudimg-amd64.img && \
    qm set 9000 --ide2 local-lvm:cloudinit && \
    qm set 9000 --boot order=scsi0 && \
    qm resize 9000 scsi0 40G && \
    qm set 9000 --serial0 socket --vga serial0
    qm template 9000
    ```

    - `apt-get update`等でのダウンロードが非常に低速になる場合、`/etc/apt/sources.list.d/ubuntu.sources`で指定しているリポジトリのURIを`http`から`https`に変更すると解決する場合がある


- 仮想マシンを1個作成する  

    先に作成した仮想マシンテンプレートをクローンして仮想マシンを作成します。  
    ブラウザ等のGUIから操作を行うか、以下を参考にコンソールから実行してください。  

    ```
    qm clone 9000 500 --name pvcc --full true
    qm set 500 --memory 4096
    qm resize 500 scsi0 40G
    qm set 500 --sshkey ~/.ssh/id_rsa.pub
    qm set 500 --ipconfig0 ip={{付与するipアドレス}},gw={{デフォルトゲートウェイ}}
    qm start 500
    ```

- 仮想マシン上で、Portable VCCセットアップ・スクリプトを実行する  

    プライベートIPアドレスが付与されているインターフェース名(`ip`コマンド等で確認)を引数に指定してください。  

    ```
    git clone https://github.com/nii-gakunin-cloud/ocs-vcp-portable.git
    cd ocs-vcp-portable
    ```

    設定ファイルを編集します。  
    - `config/vpn_catalog.yml`  

        ```
        proxmox:
            default:
                proxmox_pm_api_url: << proxmoxのAPIエンドポイントのURL eg. http://192.168.3.39:8006/api2/json >>
                proxmox_bridge: << VCコントローラで起動した仮想マシンの接続先ブリッジ名 eg. vmbr0 >>
                proxmox_ipv4_gateway: << VCコントローラで起動した仮想マシンのデフォルトゲートウェイ eg. 192.168.3.1 >>
                proxmox_target_node: << proxmoxにて、VCコントローラで起動した仮想マシンを配置するノード eg. vmconsole >>
                proxmox_template_virtual_machine_name: << clone元の仮想マシンテンプレート名 eg. vcp-ubuntu24 >>
                proxmox_storage: << proxmoxにて、VCコントローラで起動した仮想マシンが利用するストレージ名 eg. local-lvm >>
                private_network_ipmask: << VCコントローラで起動する仮想マシンのIPアドレス範囲 eg. 192.168.3.0/24 >>
        ```

    VCコントローラを起動します。
    ```
    sudo bash init_pvcc.sh <Network IF Name>

    ```

    - セットアップ・スクリプトにより以下のインストール、設定等が行われる。
        - Docker CE, Docker Composeインストール
        - Portable VCCのコンテナイメージ取得、起動
        - Portable VCCの初期設定
        - Jupyter Notebookサーバのコンテナイメージ取得、起動

    - 正常終了すると、`ocs-vcp-portable`配下に以下が出力される
        - `tokenrc`: VCP REST API アクセストークン
        - `jupyter_pass`: jupyterログイン用パスワード

- (オプション)Jupyterログイン用パスワード変更  

    以下を実行すると、パスワード変更プロンプトが表示されるので、確認用含めて2回、新しいパスワードを入力する。  

    ```
    sudo docker exec -ti cloudop-notebook-25.04.0-jupyter-8888 /opt/conda/bin/jupyter notebook password
    ```

    jupyterコンテナを再起動することで新しいパスワードが有効となる。  

    ```
    sudo docker restart cloudop-notebook-25.04.0-jupyter-8888
    ```

## 2. VCP SDK初期設定

Portable VCコントローラ用のmdx仮想マシン上に起動したJupyter Notebookで、VCP SDKの初期設定を行う。

- Jupyter Notebookサーバはmdx仮想マシンの `localhost:8888` で起動している。  
  - mdx仮想マシンに対してSSH Portforwardするか、またはmdxのDNAT+ACL設定により外部からの接続を可能にした上でブラウザからアクセスする。
  - Jupyter Notebookのログインパスワードは、Portable VCCセットアップ・スクリプト `init_pvcc.sh` の `JUPYTER_NOTEBOOK_PASSWORD` で指定した値

- `vcp_config/vcp_config.yml` の vcc.host には `127.0.0.1` を記述する。

    ```
    vcc:
        host: 127.0.0.1
        name: pvcc
    ```

- `SETUP.ipynb` の「1.2  クラウド認証情報の書き込み用 Notebook の起動」は不要。  
   （VCP既存サーバ(SSH)モードではクラウド認証情報は使用しないため。）


## 4. OCSテンプレートのNotebook実行
### 動作確認済みのテンプレート

- [CoursewareHub](https://github.com/nii-gakunin-cloud/ocs-templates/tree/master/CoursewareHub) の「構成1」(managerノードにNFSサーバを配置)
  - [011-VCノード作成-構成1](https://github.com/nii-gakunin-cloud/ocs-templates/tree/master/CoursewareHub/notebooks)
      - **(注) mdx向けの修正版を使用する必要あり**
  - 121-CoursewareHubのセットアップ-ローカルユーザ認証
  - 991-CoursewareHub環境の削除.ipynb
