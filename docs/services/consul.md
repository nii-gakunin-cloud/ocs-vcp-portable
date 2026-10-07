# Consul

## 概要

Consul は、VCPが管理する Unitgroup 等の状態を保持するKVS（Key-Valueストア）を提供するミドルウェアである。  
VCコントローラ（`occtr`）は、マシンの起動・停止等の操作結果をConsul KVSへ書き込み、管理情報として参照する。実際のマシンの状態とVCP上の管理情報に不整合が生じた場合、Consul KVSを直接編集して復旧させる必要があり、これはVC管理者の役割である。

VCPではConsulのKVSの機能のみを利用しており、Consul UI では、KVSの内容の確認・編集が可能。

> [!NOTE]
> Consul UIはVCコントローラの内部状態を確認・修復するための管理者向け機能であり、VC利用者が通常の利用で参照する必要はない。

### ACL設定

Consul はACL（アクセス制御リスト）を有効化しており、既定のポリシーは `deny`（明示的に許可されていない操作は拒否）である。  
コンテナ起動時に、`.env` の `CONSUL_INITIAL_TOKEN`（UUID）が初期管理者用トークン（`initial_management` token）として設定される。VCコントローラ（`occtr`、`worker`、`worker-update`）は、このトークンを元にConsul KVSへアクセスする。

## アクセス

`http://{VCコントローラのアドレス}:8080/consul/` をWebブラウザで開くと、Consulの管理画面にアクセスできる。

ログイン(Log in)時に「ACL Token」欄へトークンを入力する必要がある。初期状態では、`.env` の `CONSUL_INITIAL_TOKEN` に設定されている値（管理者用トークン）を使用する。  
VCP関連の管理情報は、主に `Key/Value` 画面から確認・編集する。

> [!IMPORTANT]
> `CONSUL_INITIAL_TOKEN` は、ConsulにおけるVCP全体の管理者権限を持つトークンである。取り扱いには注意すること。


> [!NOTE]
> `CONSUL_INITIAL_TOKEN` はConsulのACLブートストラップ時（初回起動時）にのみ反映され、稼働中のトークンをローテーションすることは非サポートである。詳細は [VCコントローラ 各種操作手順 - Consul初期トークンについて](../manipulation.md#consul初期トークンconsul_initial_tokenについて) を参照。
