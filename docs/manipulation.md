# 管理操作

## VCコントローラ 停止

`docker compose stop occtr` または `docker compose down occtr` コマンドによりVCコントローラを停止することができる。

## VCコントローラ (再)起動

`docker compose start occtr` または `docker compose up -d occtr` コマンドを実行する。

## VCコントローラの破棄

不要になった VC コントローラを破棄する際には、以下の手順を踏む。

1. VCコントローラで作成したVCノード(クラウドインスタンス)が削除済みであることを確認する。  

2. VCコントローラを停止する。(Jupyter が同じ docker-compose.yml で起動している場合、まとめて削除される)    

    ```
    docker compose down -v
    ```

3. ディレクトリを削除する。  

  再構築のためにデータのみを削除する場合は、`volume` ディレクトリのみを削除する。  
  vcコントローラ（jupyter等含む）全体を削除する場合は、 `ocs-vcp-portable` ディレクトリを削除する。  


## 設定変更

### VCコントローラのイメージバージョン更新

`.env` の `OCCTR_IMAGE` を更新後、対象のコンテナ（occtr, worker, worker-update）を再作成する。  

```
docker compose pull occtr worker worker-update
docker compose up -d --scale worker=<ワーカー数> occtr worker worker-update
```

> [!NOTE]
> `occtr`, `worker`, `worker-update` は同じコンテナイメージを利用している。


### TLS証明書の更新

VCコントローラは用途が異なる2種類のTLS証明書を利用しており、更新手順もそれぞれ異なる。

- サービス間通信用SSL証明書作成 (`cert/`): occtr・vault・jupyterの各コンテナ間の内部通信で使用する証明書。互いに信頼させるための自己署名CAを用いるのが基本であり、外部（ブラウザ等）から直接検証されることは想定していない。

- nginx用証明書 (`nginx/certs/`): 利用者のブラウザ等からnginxへ外部アクセスする際にnginxがTLS終端で使用する証明書。ブラウザ等から正当な証明書として検証される必要があるため、[nginxのTLS証明書](examples.md#tls設定)の構成を採用している場合は、正規のTLSサーバ証明書を配置する必要がある。

#### サービス間通信用SSL証明書作成 (`cert/`)

自己署名証明書を再作成する場合は `tools/create_dummy_cert.sh` を実行する。

```
bash tools/create_dummy_cert.sh ./cert <有効日数>
```

再作成後、`init.sh` と同様に occtr が読み取れるよう秘密鍵の所有者・権限を設定し、証明書を利用するコンテナを再起動する。

```
sudo chown root:1000 cert/occtr.key
sudo chmod 640 cert/occtr.key
docker compose restart occtr vault jupyter
```

#### nginx用証明書 (`nginx/certs/`)

正規のTLSサーバ証明書を更新する場合、`nginx/certs/fullchain.pem` と `nginx/certs/privkey.pem` を新しい証明書で置き換えた後、nginxコンテナを再起動する。

```
docker compose restart nginx
```

> [!NOTE]
> 前段の別のロードバランサやリバースプロキシでTLS終端を行っている構成等、nginxでTLS終端を行わない構成にしている場合は、このnginx用証明書の更新は不要である。

### Grafana管理者パスワードの変更

`GF_SECURITY_ADMIN_PASSWORD` はGrafanaの初回起動時（管理者アカウント作成時）にのみ反映される値であり、`grafana-data` ボリュームが既に存在する状態で `.env` を書き換えて再起動しても、稼働中のパスワードは変更されない。  
稼働中のパスワードを変更する場合は、Grafanaのコマンドを使用する。

```
docker compose exec grafana grafana cli admin reset-admin-password <新しいパスワード>
```

### Consul初期トークン(`CONSUL_INITIAL_TOKEN`)について

`CONSUL_INITIAL_TOKEN` はConsulのACLブートストラップ時（初回起動時）にのみ反映される値であり、一度ブートストラップされたトークンは `consul-data` ボリュームに永続化される。そのため、稼働開始後に `.env` を書き換えてコンテナを再起動しても、稼働中のトークンはローテーションされない。

> [!CAUTION]
> Consul初期トークンの更新は非サポート

### workerのスケール変更

occtr用ジョブキューを処理する `worker` コンテナの数は、`--scale` オプションで変更できる。

```
docker compose up -d --scale worker=<ワーカー数>
```

## 管理機能

ポータブルVCコントローラの管理者向けの機能について説明する。

### VCコントローラのユーザの管理

* 登録されているユーザのリスト

```
# docker compose exec occtr vcc user list
```

* ユーザの登録
  * ROLE は `super` または `regular` のいずれかを指定する

```
# docker compose exec occtr vcc user add USER_NAME ROLE
```

* ユーザのロールの変更
  * ROLE は `super` または `regular` のいずれかを指定する

```
# docker compose exec occtr vcc user modify USER_NAME ROLE
```

### VCP REST APIアクセストークンの発行

VCP REST APIアクセストークンの発行はVCP SDKでの操作や、Vaultに対する秘密情報の読み書きに使用するためのアクセストークンを
VC利用者に対して発行することができる。

以下のコマンドを実行して出力される文字列が `fullaccess` 権限を持つVCP REST APIアクセストークンである。  
引数にユーザ名を指定する。指定しない場合は `nobody` という `regular` ロールのユーザを割り当てる。

```
# docker compose exec occtr vcc token create [USER_NAME]
```

以下のような文字列が表示される。この文字列をVCP利用者に配布し、VCC REST APIアクセストークンとして設定して使用する。

```
s.xxxxxxxxxxxxx
```

### クラウド仮想ネットワーク定義ファイルの更新

利用するクラウドのリージョンや仮想プライベートネットワークに関する情報をVCコントローラに登録・参照するための機能がある。これを「クラウドVPNカタログ」と呼ぶ。  

クラウドVPNカタログでは、クラウドプロバイダ毎に複数の仮想プライベートネットワークを定義することができ、ポータブルVCコントローラでは YAML 形式で記述されたファイルを `config/vpn_catalog.yml` に配置する。  

[参考: VPNカタログ項目一覧](references/vpncatalog.md)  

例として、aws用の設定を示す。  

```yaml
cci_version: '1.0'

aws:
default:
    aws_region: ap-northeast-1
    aws_vpc_subnet_id: subnet-fffffffffffffffff
    aws_vpc_security_group_id: sg-fffffffffffffffff
    aws_availability_zone: ap-northeast-1a
    private_network_ipmask: 172.30.2.0/24
```

`config/vpn_catalog.yml` は変更後に反映する必要がある。反映するには、以下のコマンドを実行する。  

```
docker compose exec occtr vcc vpncatalog set
```

※正常終了した場合、特に出力は無い。


### ログの確認

ポータブルVCコントローラコンテナの起動ログは以下のコマンドで参照する。

```
# docker compose logs occtr
```

ポータブルVCコントローラコンテナ内の `/opt/occ/var/logs` 配下にもログが出力される。

### バックアップ & リストア  

起動中のVCコントローラ関連サービスのデータをバックアップ & リストアする手順について記載する。  
なお、操作はすべて`ocs-vcp-portable` 直下で行うことを想定している。  
特に記載の無い場合、バックアップしたファイル等をリストアする場合は、元の場所に配置すればよい。  

- バックアップ  

  各コンテナのデータディレクトリは、コンテナホスト側の `volume` 配下にバインドマウントされている。  
  バックアップは、このディレクトリを退避する。  
  バックアップ対象となり得るディレクトリ・ファイルは以下の通り。
  
  > [!NOTE]
  > `docker compose down`（または `stop`）を行い、コンテナ停止後にバックアップを行うことが望ましい。

  - `volume/`  

    各コンテナ（`occtr`, `vault` 等）のデータディレクトリがマウントされているディレクトリ。  

    ex. 一式をtar ballにまとめる    
  
    ```
    sudo tar czf volume.tgz volume
    ```

  - `.env`  
  
    コンテナの環境変数設定ファイル。

  - `nginx/nginx.conf.template`  

    nginx設定ファイル。編集している場合、こちらのバックアップが推奨される。  

  - `nginx/certs`  

    nginxに設定するTLS証明書用のディレクトリ。NginxでTLSを有効化しない場合は不要。  

  - `config/`  

    VCコントローラ用の設定ファイル（`vpnカタログ`）配置用のディレクトリ。  

  > [!TIP]
  > その他変更・追加したファイルも確認すること。

- リストア

  バックアップしたディレクトリ・ファイルを再配置する。  

  - コンテナ起動済みの場合は、いったん停止する  

    ```
    docker compose down
    ```

  - （参考）`volume` ディレクトリは、コンテナ上のユーザに合わせるため、権限を維持する

    ```
    sudo tar xzfp volume.tgz --numeric-owner
    ```

  - コンテナを起動する   

    ```
    docker compose up -d --scale worker=<worker数>
    ```
