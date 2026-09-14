# サンプル集

## TLS設定

外部からNginxコンテナに直接アクセスする場合は、このNginxでTLS終端を行うのが望ましい。以下に設定手順例を示す。  

- `nginx/nginx.conf.template` を修正する  

    Nginx用の設定ファイルを修正し、TLSを有効にする。サーバ証明書のパスを指定する。  
    ここで指定するパスはコンテナ上のものであり、後述する docker-compose.yml でのマウント設定とパスを合わせる必要がある。  

```diff
- listen 8080;
- server_name localhost;
+ listen 8080 ssl; # ポート番号は任意だが、変更する場合は docker-compose.yml 上のポートバインド設定の変更が必要
+ server_name example.com;  # 実際に利用するFQDNに置き換える
+ ssl_certificate      /etc/nginx/certs/fullchain.pem;  # docker-compose.ymlのマウント設定も行う
+ ssl_certificate_key  /etc/nginx/certs/privkey.pem;  # docker-compose.ymlのマウント設定も行う
```

- サーバ証明書のマウント設定を行う  

    `nginx/nginx.conf.template`に記載したFQDNに対応する正規のTLSサーバ証明書（Let's Encrypt等で取得したもの）を配置し、コンテナにマウントする。  

    - docker-compose.yml でのマウント設定例

        ```yml
        nginx:
            volumes:
            - ./nginx/nginx.conf.template:/etc/nginx/templates/nginx.conf.template:ro
            - ./nginx/certs:/etc/nginx/certs:ro # ★サーバ証明書をマウント
        ```

        この例の場合、以下のように証明書ファイルを配置する。  

        - `nginx/certs/fullchain.pem`
        - `nginx/certs/privkey.pem`


## AWS サイト間 VPN (Site-to-Site VPN) 接続の機能を利用した IPsec 接続環境の構築例

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