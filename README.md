# 環境構築手順/環境利用手順
## はじめに
- 本稿は、クラウドサービスを利用するように設定する手順が含まれており、実施によって一定の料金が発生するものとなっています。したがって、本稿記載の手順実行においては内容を理解の上、自己責任で実施するようお願いします。可能な場合は、無料トライアルを利用した使用を行うことを推奨します。
- また、本稿は最低限の機能の確認を目的とした最低限の設定で記載しております。利用する際には、非機能要件に応じて設定を見直すことを推奨します。
- 本稿は2019年1月時点の情報に基づいており、現在の情報と異なっている可能性があります。本稿の内容は執筆者独自の見解であり、所属企業における立場、戦略、意見を代表するものではありません。

## 前提作業
- 本手順では、下記作業が完了しているものとします。

- ローカルPC上への下記モジュールの最新版のインストール
    - Google Cloud SDK (gcloud)
        - https://cloud.google.com/sdk/downloads?hl=ja
    - terraform
        - https://learn.hashicorp.com/terraform/getting-started/install.html
    - git
    - openssl
    - wget

- GCPを利用するためのGoogleアカウントの作成

- GCPプロジェクトの作成

- GCPコンソール上での各種APIの有効化
    - Cloud IoT Core
    - Cloud Pub/Sub
    - Cloud Functions
    - BigQuery
    - Cloud Storage(注)

注：Cloud Storageはシステム構成上には記載がありませんが、BigQueryの一時ファイル保管先、およびCloud Functionsのアーカイブ保管先として利用するため、あわせて有効化しておきます。

## 環境構築手順
### 1. gitリポジトリのクローン
- ローカルPC上の任意のディレクトリを作成し、git cloneコマンドにより、本リポジトリを同期します。
```shell
cd {BASE_DIR}/
git clone https://github.com/godajaiko21/iphone-data_to_bq.git
```

### 2. サービスアカウントの作成とJSONキーファイルのダウンロード
- 本手順ではTerraformを使用したクラウドサービスのデプロイを行いますが、そのTerraformが利用するサービスアカウントの作成を行います。

#### 2.1. サービスアカウントJSONキーの作成
- 下記サイトの「サービス アカウント キーの作成」に記載の手順をもとに、サービスアカウントの作成とJSONキーファイルのダウンロードを行ってください。
    - https://cloud.google.com/iam/docs/creating-managing-service-account-keys?authuser=19&hl=ja
    - 注1： 「サービス アカウントの権限（オプション）」画面では、下記の役割を追加してください。
        - Cloud IoT 管理者
        - Pub/Sub 管理者
        - Cloud Functions 開発者
        - BigQuery 管理者
        - ストレージ管理者
    - 注2: 「キーのタイプ」では、JSONを選択してください。

#### 2.2. サービスアカウントJSONキーの配置
- ダウンロードしたJSONファイルは、`service-account.json`とリネームした上で、`iphone-data_to_bq/files/`内に配置します。

### 3. GCP環境のセットアップ
#### 3.1. Terraformの設定ファイルの編集
- `iphone-data_to_bq/terraform/variables.tf`ファイルを書き換えます。
    - `{{ }}`で囲まれた文字列をすべて編集します。

#### 3.2. Terraformの実行
- 下記コマンドにより、Terraformを実行し、GCPサービスのセットアップを行います。
    - サービス有効化によって課金が発生しますのでご注意ください。
```shell
cd {BASE_DIR}/iphone-data_to_bq/terraform
terraform init
terraform plan
# -> エラーがないことを確認
terraform apply
# -> yes
# -> エラーがないことを確認
```

#### 3.3. 実行結果の確認
- GCPコンソール上から、下記のサービスがデプロイされたことを確認します。
    - Cloud IoT Core
    - Cloud Pub/Sub
    - Cloud Functions
    - BigQuery
    - Cloud Storage

### 4. Cloud IoT Coreへのデバイスの登録
#### 4.1. SSH鍵の作成
- Cloud IoT Coreと通信するデバイス用のSSH鍵(公開鍵/秘密鍵)を作成します。
```shell
cd {BASE_DIR}/iphone-data_to_bq/files
openssl req -x509 -newkey rsa:2048 -keyout rsa_private.pem -nodes -out rsa_cert.pem -subj "/CN=unused"
```

#### 4.2. gcloudコマンドを使ったデバイスの登録
- 作成したSSH公開鍵`rsa_cert.pem`はを引数に指定し、Cloud IoT Coreにデバイスを登録します。
    - `{{ }}`で囲まれた文字列は編集してください。`REGISTRY_ID`は手順3.1.と整合するようにします。
```shell
cd {BASE_DIR}/iphone-data_to_bq/files
gcloud iot devices create {{DEVICE_ID}} --region=asia-east1 --registry={{REGISTRY_ID}} --public-key path=rsa_cert.pem,type=RSA_X509_PEM
```

### 5. iPhoneに転送するファイルの準備
- 今回は、iCloud Driveを使って、PCの`{BASE_DIR}/iphone-data_to_bq/pythonista`上にあるファイルを、iPhone上のPythonistaに転送することとします。Pythonistaではダウンロード可能なファイルの拡張子の制約があるため、一部拡張子は`.txt`に変換しています。

#### 5.1. 秘密鍵ファイルの準備
- 手順4で作成したSSH秘密鍵`rsa_private.pem`は、拡張子を`.txt`に変え、`iphone-data_to_bq/pythonista`ディレクトリにコピーします。
```shell
cd {BASE_DIR}/iphone-data_to_bq/pythonista
cp rsa_private.pem ../pythonista/rsa_private.txt
```

#### 5.2. GoogleのCAルート証明書の準備
- GoogleのCAルート証明書をインターネット上から入手します。
```shell
cd {BASE_DIR}/iphone-data_to_bq/pythonista
wget https://pki.google.com/roots.pem -O roots.txt
```

#### 5.3. `send_to_cloudiot.sh`の準備
- `files/send_to_cloudiot.sh`スクリプトの中身を編集します。
    - 手順3.1.の設定内容にあわせて、`{{ }}`で囲まれた文字列をすべて編集します。

#### 5.4. iCloud Driveへの配置
- `{BASE_DIR}/iphone-data_to_bq/pythonista`上にある下記４ファイルをiCloud Drive上の任意のディレクトリに配置します。
    - cloudiot_mqtt.py
    - roots.txt
    - rsa_private.txt
    - send_to_cloudiot.sh

### 6.iPhone上でのPythonistaのセットアップ
iPhoneに最新のPythonista3をインストールします。

#### 6.1. Pythonista3のインストール
- App StoreからiPhone上にPythonista3(有料)をインストールします。

#### 6.2. StaShの有効化
- 下記手順から、Pythonista3上でStaShを有効化します。
    - https://qiita.com/sotsuka4198/items/696225da3eaf92038cdf
```shell
import requests as r; exec(r.get('http://bit.ly/get-stash').text)
```

#### 6.3. Pythonモジュールのインストール
- StaShを起動し、ターミナルにてPythonモジュールをインストールします。
```shell
pip install paho-mqtt pyjwt
```

#### 6.4. ファイルのインポート
- iCloud Drive上の下記の4ファイルをPythonista上にインポートします。（手順は割愛）
    - cloudiot_mqtt.py
    - roots.txt
    - rsa_private.txt
    - send_to_cloudiot.sh

#### 補足
- Cloud IoT Coreへは、約1秒の間隔でiPhoneで取得された位置情報を送信する仕組みとなっています。詳細は`cloudiot_mqtt.py`の内容を参照ください。

- Pythonistaの実行のためのiPhone上の設定については、設定を割愛します。

- `cloudiot_mqtt.py`は、GCPの提供するサンプルコードをベースに作成しています。追加、あるいは修正のコメントがある箇所以外は、基本的に同じ記述となっています。
    - https://github.com/GoogleCloudPlatform/python-docs-samples/blob/master/iot/api-client/mqtt_example/cloudiot_mqtt_example.py

- Pythonistaではcryptographyが動かないため、jwt利用時には代替策をとる必要があります。
    - https://pyjwt.readthedocs.io/en/latest/installation.html
    - `cloudiot_mqtt.py`に下記記述を追加しています。
    ```python
    import jwt
    from jwt.contrib.algorithms.pycrypto import RSAAlgorithm
    from jwt.contrib.algorithms.py_ecdsa import ECAlgorithm

    try:
        jwt.unregister_algorithm('RS256')
        jwt.unregister_algorithm('ES256')
    except:
        pass

    jwt.register_algorithm('RS256', RSAAlgorithm(RSAAlgorithm.SHA256))
    jwt.register_algorithm('ES256', ECAlgorithm(ECAlgorithm.SHA256))
    ```

以上

## 環境利用手順
### 1. iPhone上でPythonistaを起動します。
### 2. Pythonista上でのStaShを起動します。
### 3. `send_to_cloudiot.sh`を実行します。
`{{NUM_MESSAGES}}`には、送信回数を指定します。（約1秒に1回の頻度でデータ送信する仕様となっています）
```
cd {DIR}
send_to_cloudiot.sh {{NUM_MESSAGES}}
```

以上
