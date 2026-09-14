# VPNカタログ項目一覧

サポートするクラウドプロバイダの VPN カタログ設定項目は以下のとおりである。  
項目名は [Terraform Provider](https://registry.terraform.io/browse/providers) におけるリソース定義名を踏襲している。


#### 共通項目

|必須|項目名|意味|例|デフォルト値|
|-----|---|----|--|---------|
||private_network_ipmask|起動する仮想マシンのIPアドレス範囲|192.168.3.0/24||
||ntp_servers|NTPサーバのリスト|||
||cloud_instance_dns_servers|DNSサーバのリスト|||

#### AWS (aws, aws_spot)

|必須| 項目名          | 意味           | 例 |デフォルト値|
|----|----------------|----------------|----|---------|
|o|aws_region|リージョン (例: ap-northeast-1)|ap-northeast-1|-|
|o|aws_vpc_subnet_id|VPCのサブネットID|subnet-fffffffffffffffff|-|
|o|aws_vpc_security_group_id|VPCのセキュリティグループID|sg-fffffffffffffffff|-|
||aws_availability_zone|サブネットのAvailabilityゾーン名|ap-northeast-1a||

> [!NOTE]
> AWS利用の場合、`aws`(オンデマンドインスタンス) と `aws_spot` （SPOTインスタンス）はそれぞれ個別に設定が必要。  
> 両方利用する場合に、対象のネットワークを共用する場合は、同じ内容を記載すれば良い。

#### Microsoft Azure (azure)

|必須| 項目名          | 意味            | 例 |デフォルト値|
|----|----------------|----------------|----|---------|
|o|azure_resource_group_name|リソースグループ名|example-resource-group| - |
|o|azure_vnet_name|仮想ネットワーク名|example-vnet| - |
|o|azure_subnet_name|サブネット名|example-subnet| - |
|o|azure_security_group_name|セキュリティグループ名|example-nsg| - |
|o|azure_location|データセンターのリージョン (例: japaneast, japanwest, eastus)|japaneast| - |
||azure_zone||||

#### さくらのクラウド (sakura)

|必須|項目名|意味|例|デフォルト値|
|----|-----|---|---|---------|
|o|sakura_local_switch_id|プライベートネットワークに接続するローカルスイッチのID|123456789012||
|o|sakura_private_subnet_gateway_ip|プライベートサブネットのデフォルトゲートウェイ IP アドレス|192.168.1.1||
|o|sakura_zone|ゾーンの名前 (例: tk1a, is1a)|tk1a||

> [!NOTE]
> さくらのクラウドのゾーンは、リージョンとゾーンを合わせた形で指定する必要がある。例えば、東京リージョンのゾーン1を指定する場合は `tk1a` を指定する。
> [参考: リージョン・ゾーン](https://manual.sakura.ad.jp/cloud/support/region-zone.html)

#### Google Cloud Platform（gcp）

|必須|項目名|意味|例|デフォルト値|
|----|-----|----|--|---------|
|o|gcp_project|プロジェクト名||||
|o|gcp_subnetwork|サブネット名||||
|o|gcp_region|リージョン||||
|o|gcp_zone|ゾーン||||

#### VMware vSphere (vmware)

|必須|項目名|意味|例|デフォルト値|
|----|-----|---|---|---------|
|o|vmware_vsphere_server|vCenter/ESXiサーバのアドレス/FQDN|||
|o|vmware_allow_unverified_ssl|vCenter/ESXiサーバ接続時にTLS証明書の検証を行うか(true/false)|false||
|o|vmware_vsphere_datacenter_name|データセンター名|dc-01||
|o|vmware_vsphere_resource_pool_name|リソースプール名|parent||
|o|vmware_vsphere_network_name|仮想マシンが接続するネットワーク名|VM Network||
|o|vmware_vsphere_network_mask|上記ネットワークのサブネットマスクのプレフィックス長|24||
|o|vmware_template_virtual_machine_name|clone元の仮想マシンテンプレート名|vcp-ubuntu24||
|o|vmware_ipv4_gateway|VCコントローラで起動した仮想マシンのデフォルトゲートウェイ|192.168.3.1||
||vmware_virtual_machine_domain|起動する仮想マシンに付与するドメイン名|machinea.example.com||

#### MDX2 (mdx2)

|必須|項目名|意味|例|デフォルト値|
|----|-----|---|---|---------|
|o|tenant_name|OpenStackのテナント(プロジェクト)名|example-tenant|-|
|o|network_name|VCノードが接続するネットワーク名|example-network|-|
|o|security_group|適用するセキュリティグループ名|default|-|
||domain_id|認証に利用するOpenStackのドメインID|default||

#### Oracle Cloud Infrastructure (oracle)

|必須|項目名|意味| 例 |デフォルト値|
|----|-----|----|----|---------|
|o|oracle_tenancy_ocid|テナンシID||-|
|o|oracle_compartment_id|コンパートメントID||-|
|o|oracle_subnet_id|サブネットID||-|
|o|oracle_region|リージョン||-|
|o|oracle_availability_domain|可用性ドメイン||-|

#### Proxmox VE (proxmox)

|必須|項目名|意味|例|デフォルト値|
|----|-----|------------------------|--|--------|
|o|proxmox_target_nodes|proxmoxにて、VCコントローラで起動した仮想マシンを配置するノード|vmconsole|-|
|o|proxmox_template_virtual_machine_name|clone元の仮想マシンテンプレート名|vcp-ubuntu24|-|
|o|proxmox_pm_api_url|proxmoxのAPIエンドポイントのURL|http://192.168.3.39:8006/api2/json|-|
|o|proxmox_ipv4_gateway|VCコントローラで起動した仮想マシンのデフォルトゲートウェイ|192.168.3.1|-|
|o|proxmox_bridge|VCコントローラで起動した仮想マシンの接続先ブリッジ名|vmbr0|-|
|o|proxmox_storage|proxmoxにて、VCコントローラで起動した仮想マシンが利用するストレージ名|local-lvm|-|
||proxmox_pm_tls_insecure|proxmoxサーバへの接続時、tls接続の検証を行わない|False|False|
||pm_parallel|proxmox 上の同時処理数|2|2|

#### オンプレミス (onpremises)

※ 現状項目無し（但しonpremisesの設定は必要なため、空の定義を行う）
