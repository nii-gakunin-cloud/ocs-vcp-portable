# ポータブル版VCPのセットアップ手順 (for mdx1)

!!! note

    プロバイダ契約やポイント購入等、プロジェクト設定は済んでいる前提

## 0. 概要

1. [仮想マシン作成](#machine)
1. [ネットワーク設定](#nw)
1. [Potable VCコントローラ & Jupyterセットアップ](#vcc-setup)


## 1. 仮想マシン作成 <a id="machine"></a>

仮想マシンを１つ起動します。（[mdx1の利用マニュアル](https://docs.mdx.jp/ja/index.html#id2)）  

- デプロイ  

    - 最低スペック: CPUパック*4, ディスクサイズ40GB
    - 動作確認済み仮想マシンテンプレート
        - `10_Ubuntu 22.04 LTS (Vendor)`
        - `10_Ubuntu 24.04 LTS (Vendor)`

## 2. ネットワーク設定 <a id="nw"></a>

- ACL  

    マシンにアクセスするため、ACLの設定を行い、必要な通信を許可してください。  

    - 8080: Jupyter, grafana等アクセス
    - 22: SSH

- DNAT  

    グローバルIPアドレス宛ての外部通信を対象マシンへ転送するため、DNATの設定を行ってください。

## 3. Potable VCコントローラ& Jupyterセットアップ <a id="vcc-setup"></a>
 
[クイックスタート](README.md)等を参考に、起動した仮想マシンでの構築作業を進めてください。  
