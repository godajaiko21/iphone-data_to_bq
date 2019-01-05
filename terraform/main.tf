## General Settings
provider "google" {
  credentials = "${file("${var.service_account_json_path}")}"
  project     = "${var.google_project}"
  region      = "${var.google_project_region}"
}

provider "google-beta" {
  credentials = "${file("${var.service_account_json_path}")}"
  project     = "${var.google_project}"
  region      = "${var.google_project_region}"
}

## Cloud IoT Core
resource "google_cloudiot_registry" "registry" {
  name = "${var.google_cloudiot_registry}"

  project = "${var.google_project}"
  region  = "${var.google_cloudiot_region}"

  event_notification_config = {
    pubsub_topic_name = "${google_pubsub_topic.cloudiot_telemetry.id}"
  }

  state_notification_config = {
    pubsub_topic_name = "${google_pubsub_topic.cloudiot_devicestatus.id}"
  }

  http_config = {
    http_enabled_state = "HTTP_DISABLED"
  }

  mqtt_config = {
    mqtt_enabled_state = "MQTT_ENABLED"
  }
}

## Cloud Pub/Sub
resource "google_pubsub_topic" "cloudiot_devicestatus" {
  name = "${var.google_pubsub_cloudiot_devicestatus_topic}"
}

resource "google_pubsub_topic" "cloudiot_telemetry" {
  name = "${var.google_pubsub_cloudiot_telemetry_topic}"
}

## Cloud Functions
resource "google_storage_bucket" "cf_archive_bucket" {
  provider = "google"
  name     = "${var.google_storage_bucket_cfarch_name}"
  location = "${var.google_storage_bucket_cfarch_location}"
}

resource "google_storage_bucket_object" "cf_archive_file" {
  provider = "google"
  name     = "${var.google_storage_bucket_cfarch_archive_name}"
  bucket   = "${google_storage_bucket.cf_archive_bucket.name}"
  source   = "${var.google_storage_bucket_cfarch_archive_path}"
}

resource "google_cloudfunctions_function" "pubsub_to_bq" {
  provider              = "google-beta"
  name                  = "${var.google_cloudfunctions_function_name}"
  source_archive_bucket = "${google_storage_bucket.cf_archive_bucket.name}"
  source_archive_object = "${google_storage_bucket_object.cf_archive_file.name}"

  event_trigger = {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = "${google_pubsub_topic.cloudiot_telemetry.name}"
  }

  runtime     = "python37"
  entry_point = "${var.google_cloudfunctions_function_name}"

  environment_variables = {
    DATASET = "${google_bigquery_dataset.bq_dataset.dataset_id}"
    TABLE   = "${google_bigquery_table.bq_table.table_id}"
  }
}

## BigQuery
resource "google_bigquery_dataset" "bq_dataset" {
  provider   = "google"
  dataset_id = "${var.google_bigquery_dataset_id}"
  project    = "${var.google_project}"
  location   = "${var.google_bigquery_dataset_location}"
}

resource "google_bigquery_table" "bq_table" {
  provider   = "google"
  dataset_id = "${google_bigquery_dataset.bq_dataset.dataset_id}"
  project    = "${var.google_project}"
  table_id   = "${var.google_bigquery_table_id}"

  schema = "${file("${var.google_bigquery_schema_json_path}")}"
}

resource "google_storage_bucket" "bq_tmpbucket" {
  provider = "google"
  name     = "${var.google_storage_bucket_bqtmp_name}"
  location = "${var.google_storage_bucket_bqtmp_location}"
}

resource "google_storage_bucket_object" "bq_tmpdir" {
  provider = "google"
  name     = "${var.google_storage_bucket_bqtmp_dirname}/${var.google_storage_bucket_bqtmp_blankfile}"
  bucket   = "${google_storage_bucket.bq_tmpbucket.name}"
  source   = "${var.google_storage_bucket_bqtmp_blankfile}"
}
