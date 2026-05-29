# ポータブル版VCPのセットアップ手順 (for mdx)

## 0. 概要

1. mdxでPortable VCコントローラ用に仮想マシンを作成する。
2. Potable VCコントローラと同じ仮想マシン上のJupyter NotebookでVCP SDKを設定する。
3. VCノードを既存サーバ(SSH)モードで使用するためのmdx仮想マシンを作成する。
4. OCSテンプレートのNotebookを実行する。

## 1. Portable VCコントローラ用のmdx仮想マシンを作成

- mdxの仮想マシンを1個作成する。  

    - mdx仮想マシンテンプレート: `10_Ubuntu 24.04 LTS (Vendor)`  
        ※動作確認済みの公式提供イメージ。以下このイメージを前提とした設定内容を記載している。
    - メモリ量: 4GB以上
    - 仮想ディスク容量: 40GB以上
    - (備考) ユーザ名は`mdx-user01`

- 起動したマシンにログインし、以下を実行する

    ```
    git clone https://github.com/nii-gakunin-cloud/ocs-vcp-portable.git
    cat <<EOF >config/vpn_catalog.yml
    cci_version: '1.0'
    onpremises:
    default: {}
    EOF
    sudo bash init_pvcc.sh ens192
    ```

    正常終了すると、画面上に **jupyterログイン用パスワード**と**初期vccアクセストークン** が表示されるため、控えておく。


## 2. VCP SDK初期設定

Portable VCコントローラ用のmdx仮想マシン上に起動したJupyter Notebookで、VCP SDKの初期設定を行う。

- Jupyter Notebookサーバはmdx仮想マシンの `localhost:8888` で起動している。  
  - mdx仮想マシンに対してSSH Portforwardするか、またはmdxのDNAT+ACL設定により外部からの接続を可能にした上でブラウザからアクセスする
  - `config/nginx.conf`でフォワーディング設定を行い、nginxコンテナを再起動することで設定変更も可能
  - Jupyter Notebookの初期ログインパスワードは、`cred/.jupyter_pass`に記載  
    ※ マニュアル（`quickstart.md`）に記載の手順で、任意のパスワードに変更してください。

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
- [MCJ-CloudHub](https://github.com/nii-gakunin-cloud/mcj-cloudhub)
