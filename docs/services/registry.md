# Registry

## 概要

Registry は、[Docker Registry](https://distribution.github.io/distribution/) を用いたプライベートコンテナレジストリ機能を提供する。VCPでは、用途に応じて以下の2つのレジストリコンテナを起動する。

|コンテナ|用途|公開ポート|
|---|---|---|
|`registry-vcpmirror`|VCP公式のベースコンテナイメージ（`harbor.vcloud.nii.ac.jp`）に対するプロキシキャッシュ|5000(TCP)|
|`registry-local`|独自にビルドしたコンテナイメージをパブリックなレジストリに登録せずローカルで利用するためのレジストリ|5001(TCP)|

> [!NOTE]
> いずれもVCPネットワーク内での利用を想定している。

## registry-vcpmirror（ベースイメージのキャッシュ）

外部のコンテナレジストリ（`harbor.vcloud.nii.ac.jp`）に対するプロキシキャッシュ（[`pull through cache`](https://distribution.github.io/distribution/recipes/mirror/)）として動作する。

VCノードやVCP関連コンテナ（`occtr`、`jupyter` 等）は、VCP公式のベースコンテナイメージの取得時にこのレジストリを経由することで、外部レジストリへの重複したアクセスを抑え、イメージ取得を高速化する。取得したイメージは `./volume/registry-vcpmirror/data` 以下にキャッシュとして保存される。

`docker-compose.yml` では以下の環境変数を設定している。

|環境変数|内容|
|---|---|
|`REGISTRY_PROXY_REMOTEURL`|プロキシ対象の外部コンテナレジストリのURL（`https://harbor.vcloud.nii.ac.jp`）|

> [!NOTE]
> このコンテナは pull-through cache として構成されており、公式には push はサポートされていない。独自にビルドしたイメージの登録・利用には `registry-local` を用いる。

## registry-local（独自イメージ用ローカルレジストリ）

プロキシ設定を持たない、通常のコンテナレジストリとして動作する。VC利用者が独自にビルドしたコンテナイメージを、パブリックなコンテナレジストリに登録することなく、VCPネットワーク内に閉じた形でpush・利用できる。

イメージは `./volume/registry-local/data` 以下に保存される。

> [!NOTE]
> 認証等のアクセス制御は設定されていないため、登録するイメージの取り扱いには注意すること。

### 利用例

コンテナイメージをプライベートレジストリにpushし、他のマシンから利用する例を示す。  

- VCコントローラ（コンテナ）が稼働しているマシンホスト上でイメージをpushする  

    まずは、イメージを用意する。ここではVCP提供のベースコンテナイメージをPull・tagづけすることでオリジナルイメージの作成を疑似的に再現する。  

    ```
    $ docker pull harbor.vcloud.nii.ac.jp/vcp/base:3.0.0-alpine3.22-dev
    3.0.0-alpine3.22-dev: Pulling from vcp/base
    6a0ac1617861: Pull complete
    cb420aebb57f: Pull complete
    ~~~~~~~~~~~~~~~~~~~~~
    ```  

    tagを変更する。  

    ```
    $ docker tag harbor.vcloud.nii.ac.jp/vcp/base:3.0.0-alpine3.22-dev localhost:5001/original-basecontainer:test
    ```  

    イメージを登録する。  

    ```
    $ docker push localhost:5001/original-basecontainer:test
    The push refers to repository [localhost:5001/original-basecontainer]
    760d23393b66: Pushed
    837660b3338e: Pushed
    ~~~~~~~~~~~~~~~~~~~~~
    test: digest: sha256:fba26d5f580ea8b1f92b7a27c5d3b2b30e16e89d125c063546c46402ad83ab42 size: 6386
    ```

- pushしたコンテナイメージを用いてベースコンテナ（VCノード）を起動  

    vcpsdkを利用してVCノードを起動する（設定一部抜粋）  

    ```
    ugroup = vcp.create_ugroup("vcpexample", "compute")
    spec = vcp.get_spec(provider, flavor)
    # Base container image
    spec.image = "<vcコントローラのIPアドレス>:5001/original-basecontainer:test"
    ```

    > [!NOTE]
    > VCノードは、起動時にDockerエンジンの `insecure-registries` として `<vcコントローラのIPアドレス>:5000`（`registry-vcpmirror`）および `<vcコントローラのIPアドレス>:5001`（`registry-local`）をあらかじめ登録した状態で構築されるため、上記のようにTLSなしでイメージをpullできる。この2つ以外のプライベートレジストリをVCノードから利用する場合は別途Dockerエンジンの設定が必要になるが、VCPとしてはサポート対象外である。

    VCノード（ベースコンテナ）が稼働するホストマシン上で、そのベースコンテナイメージを確認すると以下のようになっている。  
  
    ```
    ubuntu@vcp-23c70f5c:~$ sudo docker ps
    CONTAINER ID   IMAGE                                            COMMAND                  CREATED              STATUS              PORTS     NAMES
    67a78fd88d23   <vcコントローラのIPアドレス>:5001/original-basecontainer:test   "supervisord -c /etc…"   About a minute ago   Up About a minute             mynode
    ```

## 稼働状況の確認

Grafanaの `VCP Metrics` ダッシュボードの `Private registry container` パネルから、`registry-vcpmirror` のキャッシュ要求数・ヒット数、およびリクエストのレイテンシ(P95)を確認できる。詳細は [Grafana](./grafana.md) を参照。
