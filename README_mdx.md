# ポータブル版VCPのセットアップ手順 (for mdx)

## 0. 概要

1. mdxでPortable VCコントローラ用に仮想マシンを作成する。
2. Potable VCコントローラと同じ仮想マシン上のJupyter NotebookでVCP SDKを設定する。
3. VCノードを既存サーバ(SSH)モードで使用するためのmdx仮想マシンを作成する。
4. OCSテンプレートのNotebookを実行する。

## 1. Portable VCコントローラ用のmdx仮想マシンを作成

- mdxの仮想マシンを1個作成する。
    - mdx仮想マシンテンプレート: `00_Ubuntu-2204-server`
    - メモリ量: 4GB以上
    - 仮想ディスク容量: 40GB以上

- mdxの仮想マシン上で、Portable VCCセットアップ・スクリプトを実行する。
    - `./mdx/init_mdx_pvcc.sh` を実行する。（sudo権限が必要）
    - セットアップ・スクリプトにより以下のインストール、設定等が行われる。
        - Docker CE, Docker Composeインストール
        - Portable VCCのコンテナイメージ取得、起動
        - Portable VCCの初期設定
        - Jupyter Notebookサーバのコンテナイメージ取得、起動
    - 正常終了すると、VCP REST API アクセストークンが `./tokenrc` ファイルに出力される。

## 2. VCP SDK初期設定

Portable VCコントローラ用のmdx仮想マシン上に起動したJupyter Notebookで、VCP SDKの初期設定を行う。

- Jupyter Notebookサーバはmdx仮想マシンの `localhost:8888` で起動している。  
  - mdx仮想マシンに対してSSH Portforwardするか、またはmdxのDNAT+ACL設定により外部からの接続を可能にした上でブラウザからアクセスする。
  - Jupyter Notebookのログインパスワードは、Portable VCCセットアップ・スクリプト `init_mdx_pvcc.sh` の `JUPYTER_NOTEBOOK_PASSWORD` で指定した値

- `vcp_config/vcp_config.yml` の vcc.host には `127.0.0.1` を記述する。

    ```
    vcc:
        host: 127.0.0.1
        name: pvcc
    ```

- `SETUP.ipynb` の「1.2  クラウド認証情報の書き込み用 Notebook の起動」は不要。  
   （VCP既存サーバ(SSH)モードではクラウド認証情報は使用しないため。）

## 3. VCノード用のmdx仮想マシンを作成

VCPの既存サーバ(SSH)モードを使用するために必要なmdx仮想マシンの設定は以下のとおり。

- sshd Port を 22 から 20022 に変更
- Docker CE をインストール
- Portable VCコントローラ公開鍵 `./volume/opt/occ/.ssh/id_rsa.pub` を `~mdxuser/.ssh/authorized_keys` に追加する。  
  （VCコントローラからVCノード用のmdx仮想マシンにSSH接続する必要があるため。）

## 4. OCSテンプレートのNotebook実行
### 動作確認済みのテンプレート

- [CoursewareHub](https://github.com/nii-gakunin-cloud/ocs-templates/tree/master/CoursewareHub) の「構成1」(managerノードにNFSサーバを配置)
  - [011-VCノード作成-構成1](https://github.com/nii-gakunin-cloud/ocs-templates/tree/master/CoursewareHub/notebooks)
      - **(注) mdx向けの修正版を使用する必要あり**
  - 121-CoursewareHubのセットアップ-ローカルユーザ認証
  - 991-CoursewareHub環境の削除.ipynb

### (参考情報)
#### CoursewareHubテンプレートのmdx向け修正内容

##### 1. NFS用Baseコンテナイメージの修正

  - [`00-mkfs.sh`](https://github.com/nii-gakunin-cloud/ocs-templates/tree/master/CoursewareHub/docker/bc/nfsd/etc/vcp/rc.d) を削除してイメージを再作成する
    * ビルド済みイメージの公開場所:  
      `public.ecr.aws/niivcp/vcp/coursewarehub:bc-nfs-onpremises`

##### 2. [011-VCノード作成-構成1](https://github.com/nii-gakunin-cloud/ocs-templates/tree/master/CoursewareHub/notebooks)

  - NFS サーバ用に外部ディスクは使えないため、masterノードのホスト上の `/mnt` をBaseコンテナに volume マウントする。
    * Baseコンテナ起動時に `-v /mnt:/exportd` オプションが付く形で masterノード用の VC ノードを起動  
    `spec_mgr.params_v.append('/mnt:/exported')`

  - spec 指定を onpremises (SSHモード) 用に書き換える。以下が必須項目。
    * `ip_addresses`
    * `user_name`
    * `set_ssh_pubkey()`

  - `docker swarm init` のオプションに `--advertise-addr` を追加する。  
    (mdx仮想マシンに複数のNICがあるため、対象のNICを明示的に指定)
