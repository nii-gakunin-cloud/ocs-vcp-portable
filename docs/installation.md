# インストール

## 要件

### 動作確認済みの OS, Distribution 環境

* Ubuntu Server 22.04 LTS
* Ubuntu Server 24.04 LTS

### 必須ソフトウェア

VCコントローラの実行環境に以下のソフトウェアがインストールされていることを前提とする。

* Docker
* Docker Compose

### ディスク容量要件

10 Gbyte 以上を推奨する。

* Docker コンテナイメージ: 約 6GB
    * ポータブルVCコントローラ/worker/worker-update: 約 2GB
    * JupyterNotebook: 約 2GB
    * 他: 計約 2GB
* Docker コンテナボリューム等(最低): 約 1GB

### ネットワーク要件

対象とするクラウドの仮想ネットワーク環境上に起動するクラウドインスタンスに対して、ポータブルVCコントローラがプライベートIPアドレスでアクセスできること。

- 例
    1. VCコントローラとクラウド仮想ネットワーク環境をVPN接続する
    1. VCコントローラとクラウド仮想ネットワーク環境を同一ネットワーク上に配置する

## 準備

### 環境変数の設定

VCコントローラ起動時の環境変数設定として、 `.env` ファイルや `docker-compose.yml` ファイル等にて、以下の環境変数を設定する。  

|必須|項目名|意味|デフォルト値|備考|
|----|-----|----|-----------|---|
|✓|VCP_VCC_PRIVATE_IPMASK | クラウドインスタンスと接続可能なVCコントローラ プライベートIPアドレス (例: `10.0.2.15/24`) | - ||
|✓|GF_SECURITY_ADMIN_PASSWORD | Grafanaの管理者パスワード | - ||
|✓|SERF_ADVERTISE | Serfのadvertise addr | - | 基本的に、vccが起動するマシンのIPアドレスを指定する |
|✓|NGINX_PROXY_HOST | ユーザがアクセスする際に指定するFQDN | - ||
|✓|CONSUL_INITIAL_TOKEN | Consulの管理者用トークン(UUID) | - ||
||CONSUL_TOKEN_FILE | VCCがconsul kvsを利用するためのトークンファイルパス | `/opc/occ/var/occtr/consul_token` | |
||CONSUL_TOKEN | VCCがconsul kvsを利用するためのトークン | | 指定した場合、`CONSUL_TOKEN_FILE` より優先される |
||CONSUL_HTTP_ADDR | Consulのアドレス | `localhost:8500` | |
||CONSUL_KVS_URL | Consul kvs のURL | `http://{CONSUL_HTTP_ADDR}/v1/kv` | |
||BC_REGISTRY_HOST | コンテナレジストリホスト | `harbor.vcloud.nii.ac.jp` | ポートは固定で`5000`を使用 |
||REQUESTS_CA_BUNDLE | SSL証明書のパス | `/etc/ssl/certs/ca-certificates.crt` | |
||VAULT_API_URL | VaultAPIアクセス用URL | `https://localhost:8200/v1` | |
||REDIS_HOST | redisアクセス用ホスト指定 | `localhost` | |
||REDIS_PORT | redisアクセス用ポート指定 | `6379` | |
||REDIS_PASSWORD | redisアクセス用パスワード指定 | | |

### SSL証明書

jupyter環境からポータブルVCコントローラ・vaultに対してHTTPS通信を行うため、SSL証明書を準備する必要がある。証明書は、`cert/` ディレクトリに配置する。

- SSLサーバ証明書
    * Subject Alternative Name:  `localhost`, `127.0.0.1`, `occtr` を設定
    * ファイル: `occtr.crt`, `occtr.key`
- 上記SSLサーバ証明書を発行したCA認証局の自己署名証明書
    * ファイル: `occtr_ca.crt`

!!! note

    `tools/create_dummy_cert.sh` スクリプトを使用して、自己署名証明書を作成することができる。スクリプト実行後、`cert/` ディレクトリに `occtr_ca.crt`, `occtr.crt`, `occtr.key` の3つのファイルが生成される。

### クラウド仮想ネットワーク定義ファイル

利用するクラウドのリージョンや仮想プライベートネットワークに関する情報をVCコントローラに登録・参照するための機能がある。これを「クラウドVPNカタログ」と呼ぶ。  

クラウドVPNカタログでは、クラウドプロバイダ毎に複数の仮想プライベートネットワークを定義することができ、ポータブルVCコントローラでは YAML 形式で記述されたファイルを `config/vpn_catalog.yml` に配置する。  

クラウドVPNカタログの例を以下に示す。  

??? info "クラウドVPNカタログ記述例"

    ```yaml
    cci_version: '1.0'

    aws:
    default:
        aws_region: ap-northeast-1
        aws_vpc_subnet_id: subnet-fffffffffffffffff
        aws_vpc_security_group_id: sg-fffffffffffffffff
        aws_availability_zone: ap-northeast-1a
        private_network_ipmask: 172.30.2.0/24

    tokyo_subnet1:
        aws_region: ap-northeast-1
        aws_vpc_subnet_id: subnet-fffffffffffffffff
        aws_vpc_security_group_id: sg-fffffffffffffffff
        aws_availability_zone: ap-northeast-1c
        private_network_ipmask: 172.30.3.0/24

    us_west_subnet:
        aws_region: us-west-2
        aws_vpc_subnet_id: subnet-fffffffffffffffff
        aws_vpc_security_group_id: sg-fffffffffffffffff
        aws_availability_zone: us-west-2a
        private_network_ipmask: 172.30.5.0/24

    sakura:
    default:
        sakura_local_switch_id: ******
        sakura_private_subnet_gateway_ip: 172.23.1.1
        sakura_zone: tk1a
        private_network_ipmask: 172.23.1.0/24
    ```

!!! note

    クラウドVPNカタログの項目名や内容は、クラウドプロバイダ毎に異なる。詳細は [VPNカタログ](references/vpncatalog.md) 参照。


### VCコントローラとクラウド仮想ネットワーク間の通信設定

VCコントローラから、VCノードとして起動したインスタンスに対してプライベートIPアドレスでアクセス可能となるよう、ネットワーク設定を行う。  
例えば、クラウド仮想ネットワークとVCコントローラ間をVPN接続するために IPsec 接続環境を準備する。 

!!! note

    VCコントローラから、VCノードとして起動したインスタンスに対してプライベートIPアドレスでアクセス可能とすることが目的である。  
    したがって、VCコントローラとVCノードが同一ネットワーク上に配置されている場合は、IPsec 接続は不要である。  

??? info "AWS サイト間 VPN (Site-to-Site VPN) 接続の機能を利用した IPsec 接続環境の構築例"

    ### AWS側設定

    1. Terraform スクリプト `aws/aws_vpn.tf` を実行する  

        ```
        # Docker による実行例
        docker run -ti -v "$(pwd):/app" -w /app hashicorp/terraform init
        docker run -ti -v "$(pwd):/app" -w /app \
        -e AWS_ACCESS_KEY_ID="anaccesskey" \
        -e AWS_SECRET_ACCESS_KEY="asecretkey" \
        -e AWS_DEFAULT_REGION="ap-northeast-1" \
        hashicorp/terraform apply

        var.local_subnet
        Enter a value:   (VCコントローラ環境のサブネットを入力 例: 10.0.2.0/24)
        var.my_public_ip
        Enter a value:   (VCコントローラ環境のOutbound Public IPアドレスを入力)
        ```

    2. スクリプト実行結果として、AWS VPC に作成されたリソース情報を確認する。  

        この内容を前述の「クラウド仮想ネットワーク定義ファイル」`config/vpn_catalog.yml` に記述する。  

        ```
        Outputs:

        aws_availability_zone = ap-northeast-1a
        aws_vpc_security_group_id = sg-0387934d3cd06946f
        aws_vpc_subnet_id = subnet-0862300dba34162ed
        private_network_ipmask = 172.30.2.0/24
        ```

    3. AWS VPC Dashboard の Site-to-Site VPN Connections から、IPsec 設定ファイルを取得する。  

        - AWS VPC Dashboard > Site-to-Site VPN Connections > Download Configuration
        - Vendor: Openswan を選択し、設定ファイルをダウンロードする

    ### VC コントローラ側設定

    VCコントローラ側の IPsec 接続環境の例として、ここでは VirtualBox 上の VM (Debian 10) にLibreswan をインストールして設定する手順について説明する。  

    1. Libreswan パッケージをインストールする

        ```
        # apt-get install libreswan
        ```

    2. Libreswan を初期化する

        ```
        # ipsec initnss
        # certutil -N --empty-password -d sql:/etc/ipsec.d
        # modprobe af_key
        ```

    3. `ipsec.conf` ファイルを作成する  

        - AWS VPC Dashboard の Site-to-Site VPN Connections から取得した設定ファイルの内容を編集して利用することが可能
        * (注) `auth=esp` 指定は削除すること

        === "`/etc/ipsec.conf`"

            ```
            conn tunnel1
                authby=secret
                auto=start

                left=%defaultroute
                leftid=@tunnel1
                leftsubnets=10.0.2.0/24 # ポータブル VC コントローラ設置環境の Private Subnet
                leftsourceip=10.0.2.15 # ポータブル VC コントローラ設置環境の Private IP

                right=203.0.113.1 # クラウド側 IPsec インスタンスの Public IP
                rightsubnet=172.30.0.0/16 # クラウドインスタンスの VPC Subnet

                type=tunnel
                ikelifetime=8h
                keylife=1h
                phase2alg=aes128-sha1;modp1024
                ike=aes128-sha1;modp1024
                keyingtries=%forever
                keyexchange=ike
                dpddelay=10
                dpdtimeout=30
                dpdaction=restart_by_peer
            ```

    4. `ipsec.secrets` ファイルを作成する  

        AWS VPC Dashboard の Site-to-Site VPN Connections から取得した設定ファイルに記載された内容をコピーして利用可能。

        === "`/etc/ipsec.d/tunnel1.secrets`"

            ```
            # VCコントローラ環境の Outbound Public IP, クラウド側 IPsec の IP, 事前共有鍵を書く
            x.x.x.x 203.0.113.1: PSK "XXXXXX"
            ```

    5. IPsec を起動する  

        ```
        # ipsec pluto --logfile /var/log/ipsec.log --use-netkey --uniqueids
        ```

    6. IPsec の接続確立を確認する
        - `ipsec status` コマンドを実行し、以下の出力があること  

            >  `Total IPsec connections: loaded 1, active 1`
            >  `IPsec SA established`

        - AWS VPC Dashboard > Site-to-Site VPN Connections > Tunnel Details  
            Tunnel 1 の Status が **UP** であること

## 起動手順

### VCコントローラの起動

1. 準備  
    以下の各設定等が完了していること。  

    * 環境変数設定 (`.env`)
    * クラウド仮想ネットワーク定義ファイル (`config/vpn_catalog.yml`)
    * X509 形式 SSL 証明書 (`certs`)
      * `occtr.crt` (Private CA 利用時), `occtr.crt`, `occtr.key`
    * VCコントローラとクラウド仮想ネットワーク間の通信設定

2. 起動  

    docker compose を利用し、VC コントローラのコンテナを起動する。

    ```
    # docker-compose up -d
    ```

    コンテナが起動したことを確認する。

    ```
    ubuntu@ubuntu:~/ocs-vcp-portable$ docker ps
    CONTAINER ID   IMAGE                                                                 COMMAND                  CREATED         STATUS                  PORTS     NAMES
    1e17a50b5382   nginx:1.27.3                                                          "/docker-entrypoint.…"   1 minutes ago    Up 1 minutes                       ocs-vcp-portable-nginx-1
    da594c31e6d6   harbor.vcloud.nii.ac.jp/vcp/occtr:26.10.0                       "/usr/bin/supervisor…"   1 minutes ago      Up 1 minutes                         ocs-vcp-portable-occtr-1
    ```

3. VCコントローラ初期化  

    以下のコマンドを実行してVCコントローラを初期化する。

    ```
    # docker-compose exec occtr vcc init
    ```

!!! note "停止・削除等、その他の管理操作"

    VCコントローラの停止、再起動、破棄などの管理操作については、[VCコントローラ 各種操作手順](manipulation.md) を参照すること。


### サービス一覧  

以下の各サービスが、Dockerコンテナとして起動する。

|コンテナ|サービス|公開ポート番号|用途|
|-------|--------|-------------|----|
|occtr|VCP REST API|443|VCコントローラのREST API|
|vault|OpenBao||クラウドプロバイダの認証情報等を管理|
|serf|serf|7373(TCP),7943(TCP/UDP)|各ノードの死活監視、VCノードからのアクセス有|
|grafana|Grafana||GrafanaのWeb UI|
|nginx|Nginx|8080(TCP)|ユーザアクセスの入口|
|consul|consul|||
|jupyter|jupyter|||
|redis|redis|||
|prometheus|prometheus|||
|registry|registry|||
|worker|worker|||
|worker-update|worker-update|||

!!! note

    Grafana, jupyter は 初期設定ではnginxを通してアクセスするよう設定されている（`/grafana`, `/jupyter` でアクセス）。

## Web UI

### Grafana

VC利用者は、 `http://{VCコントローラのアドレス}:8080/grafana/` をWebブラウザで開くと
Grafanaのダッシュボードを利用できる。

デフォルトで設定されているアカウントは以下のとおり。  

- ID: `admin`
- パスワード: [GF_SECURITY_ADMIN_PASSWORD　に設定したパスワード]
