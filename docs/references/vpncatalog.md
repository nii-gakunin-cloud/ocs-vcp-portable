# VPNカタログ

サポートするクラウドプロバイダの VPN カタログ設定項目は以下のとおり。  
項目名は [Terraform Provider](https://registry.terraform.io/browse/providers) におけるリソース定義名を踏襲している。

#### 共通項目

項目名|意味| 例
-----|-------------------------------|----
private_network_ipmask|起動する仮想マシンのIPアドレス範囲|192.168.3.0/24

#### AWS (aws, aws_spot)

| 項目名          | 意味           | 例 |
|----------------|----------------|----|
|aws_vcp_subnet_id|VPCのサブネットID|subnet-fffffffffffffffff|
|aws_vcp_security_group_id|VPCのセキュリティグループID|sg-fffffffffffffffff|
|aws_region|リージョン (例: ap-northeast-1)|ap-northeast-1|
|aws_availability_zone|サブネットのAvailabilityゾーン名 (例: ap-northeast-1a)|ap-northeast-1a|

!!! note

    AWSのSPOTインスタンス利用時は、SPOTインスタンス用の定義が必要。

#### Microsoft Azure (azure)

| 項目名          | 意味            | 例 |
|----------------|----------------|----|
|azure_resource_group_name|リソースグループ名|example-resource-group|
|azure_vnet_name|仮想ネットワーク名|example-vnet|
|azure_subnet_name|サブネット名|example-subnet|
|azure_security_group_name|セキュリティグループ名|example-nsg|
|azure_location|データセンターのリージョン (例: japaneast, japanwest, eastus)|japaneast|

#### Oracle Cloud Infrastracture (oracle)

項目名|意味| 例 |Webコンソールでの確認先
----------|-------------------------------|----|-----------------------
oracle_tenancy_ocid|テナンシID||管理 >> テナンシ情報
oracle_compartment_id|コンパートメントID||アイデンティティ >> コンパートメント >> コンパートメント情報
oracle_subnet_id|サブネットID||ネットワーキング >> 仮想クラウド・ネットワーク >> VCN名 >> サブネット情報
oracle_region|リージョン||管理 >> 地域管理 >> リージョン識別子（または最上部のリージョン名 >> リージョン管理）
oracle_availability_domain|可用性ドメイン||コンピュート >> インスタンス >> インスタンス情報 (注)

!!! note

    可用性ドメインは Oracle Cloud のテナンシごとに異なり、Web UI からインスタンス作成を実行することで値を確認することができる。

#### さくらのクラウド (sakura)

項目名|意味| 例
-----|-------------------------------|----
sakura_local_switch_id|プライベートネットワークに接続するローカルスイッチのID|example-switch-id
sakura_private_subnet_gateway_ip|プライベートサブネットのデフォルトゲートウェイ IP アドレス|192.168.1.1
sakura_zone|ゾーンの名前 (例: tk1a, is1a)|tk1a

!!! note

    さくらのクラウドのゾーンは、リージョンとゾーンを合わせた形で指定する必要がある。例えば、東京リージョンのゾーン1を指定する場合は `tk1a` を指定する。
    [参考: リージョン・ゾーン](https://manual.sakura.ad.jp/cloud/support/region-zone.html)

#### Google Cloud Platform（gcp）

項目名|意味| 例|Webコンソールでの確認先
----------|-------------------------------|----|-----------------------
gcp_project|プロジェクト名||IAM & 管理 >> プロジェクト
gcp_subnetwork|サブネット名||VPC ネットワーク >> サブネット
gcp_region|リージョン||Compute Engine >> VM インスタンス >> リージョン
gcp_zone|ゾーン||Compute Engine >> VM インスタンス >> ゾーン

#### Proxmox VE (proxmox)

項目名|意味| 例
-----|-------------------------------|----
proxmox_pm_api_url|proxmoxのAPIエンドポイントのURL|http://192.168.3.39:8006/api2/json
proxmox_bridge|VCコントローラで起動した仮想マシンの接続先ブリッジ名|vmbr0
proxmox_ipv4_gateway|VCコントローラで起動した仮想マシンのデフォルトゲートウェイ|192.168.3.1
proxmox_target_node|proxmoxにて、VCコントローラで起動した仮想マシンを配置するノード|vmconsole
proxmox_template_virtual_machine_name|clone元の仮想マシンテンプレート名|vcp-ubuntu24
proxmox_storage|proxmoxにて、VCコントローラで起動した仮想マシンが利用するストレージ名|local-lvm
proxmox_pm_tls_insecure|(Optional: default=False) proxmoxサーバへの接続時、tls接続の検証を行わない|False
private_network_ipmask|VCコントローラで起動する仮想マシンのIPアドレス範囲|192.168.3.0/24
pm_parallel|(Optional: default=1) 同時実行可能なProxmox APIの処理数|2
