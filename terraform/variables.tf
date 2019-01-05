## General Settings
variable "google_project" {
  default = "{{PROJECT_ID}}"
}

variable "google_project_region" {
  default = "asia-northeast1"
}

variable "service_account_json_path" {
  default = "../files/service-account.json"
}

## Cloud IoT Core
variable "google_cloudiot_region" {
  default = "asia-east1"
}

variable "google_cloudiot_registry" {
  default = "{{REGISTRY_ID}}"
}

## Cloud Pub/Sub
variable "google_pubsub_cloudiot_devicestatus_topic" {
  default = "{{TOPIC_ID_1}}"
}

variable "google_pubsub_cloudiot_telemetry_topic" {
  default = "{{TOPIC_ID_2}}"
}

## Cloud Functions
variable "google_cloudfunctions_function_name" {
  default = "{{FUNCTION_NAME}}"
}

variable "google_storage_bucket_cfarch_name" {
  default = "{{CFARCH_BUCKET_NAME}}"
}

variable "google_storage_bucket_cfarch_location" {
  default = "asia-northeast1"
}

variable "google_storage_bucket_cfarch_archive_name" {
  default = "cloud_function.zip"
}

variable "google_storage_bucket_cfarch_archive_path" {
  default = "../files/cloud_function.zip"
}

## BigQuery
variable "google_bigquery_dataset_id" {
  default = "{{BQ_DATASET_ID}}"
}

variable "google_bigquery_dataset_location" {
  default = "asia-northeast1"
}

variable "google_bigquery_table_id" {
  default = "{{BQ_TABLE_ID}}"
}

variable "google_bigquery_schema_json_path" {
  default = "../files/schema.json"
}

variable "google_storage_bucket_bqtmp_name" {
  default = "{{BQTMP_BUCKET_NAME}}"
}

variable "google_storage_bucket_bqtmp_location" {
  default = "asia-northeast1"
}

variable "google_storage_bucket_bqtmp_dirname" {
  default = "{{BQTMP_BUCKET_DIR}}"
}

variable "google_storage_bucket_bqtmp_blankfile" {
  default = "../files/blank"
}
