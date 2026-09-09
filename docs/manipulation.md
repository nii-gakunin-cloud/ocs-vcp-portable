# 管理操作

## VCコントローラ 停止

`docker compose stop occtr` または `docker compose down occtr` コマンドによりVCコントローラを停止することができる。

## VCコントローラ (再)起動

`docker compose start occtr` または `docker compose up -d occtr` コマンドを実行する。

## VCコントローラの破棄

不要になった VC コントローラを破棄する際には、以下の手順を踏む。

1. VCコントローラで作成したVCノード(クラウドインスタンス)が削除済みであることを確認する。  

2. VCコントローラを停止する。(Jupyterが同じcomposeで起動している場合、まとめて削除されます)    

    ```
    docker compose down -v
    ```

3. `volume` ディレクトリを削除する。

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

### VPNカタログの更新

`config/vpn_catalog.yml` ファイルにVPNカタログの内容を記述し、コマンドを実行することで設定を反映させる。

```
# docker compose exec occtr vcc vpncatalog set
```

### ログの確認

ポータブルVCコントローラコンテナの起動ログは以下のコマンドで参照する。

```
# docker compose logs occtr
```

ポータブルVCコントローラコンテナ内の `/opt/occ/var/logs` 配下にもログが出力される。
