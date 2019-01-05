def pubsub2bq(event, context):
    import os
    import json
    import base64
    import logging

    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from google.cloud import bigquery

    ## 環境変数をload
    DATASET    = os.environ['DATASET']
    TABLE      = os.environ['TABLE']

    ## Cloud Pub/Subからデータ取得
    logging.info("Fetch data from Cloud Pub/Sub")
    data = json.loads(base64.decodestring(event['data'].encode("ascii")).decode("utf8"))
    logging.info(json.dumps(data))

    ## レコードを生成してBigQueryにinsert
    logging.info("Insert data into BigQuery")
    output_row = []
    output_row.append([
        data['created'],
        data['location']['latitude'],
        data['location']['longitude'],
        data['location']['altitude'],
        data['location']['timestamp'],
        data['location']['horizontal_accuracy'],
        data['location']['vertical_accuracy'],
        data['location']['speed'],
        data['location']['course']
    ])
    bq_client   = bigquery.Client()
    dataset_ref = bq_client.dataset(DATASET)
    table_ref   = dataset_ref.table(TABLE)
    table_obj   = bq_client.get_table(table_ref)
    error       = bq_client.insert_rows(table_obj, output_row) 

    ## エラーチェック&終了処理
    if len(error) > 0:
        logging.error("An error has occurred: {}".format(json.dumps(error)))
    else:
        logging.info("Successfully finished.")
