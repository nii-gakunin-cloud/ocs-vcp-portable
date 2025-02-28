# ポータブル版VCPのセットアップ手順 (for さくらのクラウド)

## 0. 概要

1. さくらのクラウドでPortable VCコントローラ用のサーバ、内部ネットワークを準備する。
2. Portable VCコントローラをセットアップする。
3. Portable VCコントローラと同じサーバ上のJupyter NotebookでVCP SDKを設定する。
4. VCノードの起動確認を行う。

## 1. Portable VCコントローラ用のサーバ、内部ネットワークの準備

- さくらのクラウドでサーバを1個作成する。
    - アーカイブ選択: `Ubuntu Server 24.04 LTS 64bit`
      * **注意** `(cloudimg)` 表記の **無いほう** を選択
    - メモリ量: 4GB以上
    - 仮想ディスク容量: 40GB以上
    - NIC: インターネットに接続

- ローカルネットワーク用のスイッチを1個作成する。
    - https://manual.sakura.ad.jp/cloud/network/switch/router-switch.html
    - ルータ機能は **不要**

- 作成したサーバに、NICを1個追加し、ローカルネットワーク用スイッチに接続する。
    - NICの追加 <https://manual.sakura.ad.jp/cloud/server/nic.html#id7>
    - NIC接続先の編集 <https://manual.sakura.ad.jp/cloud/server/nic.html#server-nic-edit>
    - サーバのOSからは、ネットワーク・インターフェースとして新たに `eth1` が出現する。

## 2. Portable VCコントローラのセットアップ

さくらのクラウドのサーバ上で以下の構築作業を行う。  

- さくらのクラウド向けネットワーク初期化設定 `./config/sakura_config.yml` を作成する。
    - さくらのクラウドで起動するVCノードに割り当てるプライベートIPアドレスを登録する。 

    ```
    default: # クラウド仮想ネットワーク定義ファイル上のネットワーク名
      prefix_len: 24
      ip_addresses:
        - 172.23.1.12
        - 172.23.1.13
        - 172.23.1.14
        - 172.23.1.15
        - 172.23.1.16
    ```

- さくらのクラウドのサーバ上で、Portable VCCセットアップ・スクリプトを実行する。 
    - `./sakuracloud/init_sakura_pvcc.sh` を実行する。（sudo権限が必要）  

      ```
      sudo bash ./sakuracloud/init_sakura_pvcc.sh <スイッチのリソースID> <ゾーンID> <スイッチのネットワークアドレス>"
      ```

      ※ **`スイッチのリソースID`**: スイッチの情報画面で確認  
      ※ **`ゾーンID`**: `is1a` `is1b` `tk1a` `tk1v` のいずれか  
      ※ **`スイッチのネットワークアドレス`**: スイッチ一覧画面やサーバ一画面のスイッチ情報の「ネットワーク」で確認  

    - セットアップ・スクリプトにより以下のインストール、設定等が行われる。
        - Docker CE, Docker Composeインストール
        - Portable VCCのコンテナイメージ取得、起動
        - Jupyter Notebookサーバのコンテナイメージ取得、起動

    - 正常終了すると、VCP REST API アクセストークンが `./tokenrc` ファイルに出力される。

## 3. VCP SDK初期設定

Portable VCコントローラ用のサーバ上に起動したJupyter Notebookで、VCP SDKの初期設定を行う。

- Jupyter Notebookは `localhost:8888` で起動している。  
  - デフォルトではインターネット経由でどこからでもアクセス可能となるため、適切にパケットフィルタ等を設定する。
  - Jupyter Notebookのログインパスワードは、Portable VCCセットアップ・スクリプト `init_sakura_pvcc.sh` の `JUPYTER_NOTEBOOK_PASSWORD` で指定した値

- Jupyter Notebookへログイン後、 `SETUP.ipynb` を開いて先頭セルから実行する。
  - `vcp_config/vcp_config.yml` の vcc.host には `127.0.0.1` を記述する。

    ```
    vcc:
        host: 127.0.0.1
        name: pvcc
    ```

  - 「1.2  クラウド認証情報の書き込み用 Notebook の起動」で作業用Notebookを開き、さくらのクラウドを設定する。
      - さくらのクラウドのAPIキーに含まれる「アクセストークン」と「アクセストークンシークレット」を入力し、Vaultサーバに保存する。
      - APIキー <https://manual.sakura.ad.jp/cloud/api/apikey.html>

## 4. VCノード起動確認

- Jupyter Notebookへログイン後のトップページにある「VCP SDKを利用するサンプルコード」のNotebookから選択して実行する。
  - さくらのクラウドノードの起動 `sdk_test/papermill/04_exec_server-sakura.ipynb`

## 5. ディスクサイズ・プランに関する注意点

- さくらのクラウドでは、利用するリージョンとディスクプラン (HDD or SSD) で指定可能なディスクサイズが異なる（細かく決められている）ため注意が必要。
  * <https://cloud.sakura.ad.jp/specification/server-disk/#server-disk-content02>
- ディスクサイズ (単位:GB) は、VCP SDK で Unit 作成時に `spec` として指定することが可能。
  * `spec.sakuracloud_disk_size = 100`
- ディスクプラン (標準プラン / SSDプラン) は、 `vcp_config/vcp_flavor.yml` 設定ファイルで記述する必要がある。
  * 現状、 `spec.sakuracloud_disk_plan = "ssd"` のように `flavor` で設定したプラン名を上書きすることはできない。（VCP SDKにおける既知の制限事項）
