provider "google" {
    project = var.PROJECT_ID
    region = var.REGION
    zone = var.ZONE
    impersonate_service_account = var.TF_SERVICE_ACCOUNT
}

resource "google_storage_bucket" "function_code" {
 name          = "queue_times_cloud_function_code"
 location      = "us-central1"
 storage_class = "STANDARD"
#  force_destroy = true

 uniform_bucket_level_access = true
}

# Upload a text file as an object
# to the storage bucket

resource "google_storage_bucket_object" "cloud_func_zip" {
 name         = "queue-times-ingestion-cloud-function.zip"
 source       = "../queue-times-ingestion-cloud-function/queue-times-ingestion-cloud-function.zip"
 content_type = "text/plain"
 bucket       = google_storage_bucket.function_code.id
}

resource "google_storage_bucket" "raw_data" {
 name          = "raw_data_queue_times"
 location      = "us-central1"
 storage_class = "STANDARD"
}

resource "google_storage_bucket" "dataflow_bucket" {
 name          = "wait-times-dataflow"
 location      = "us-central1"
 storage_class = "STANDARD"
 force_destroy = true

 uniform_bucket_level_access = true
}

resource "google_pubsub_topic" "default" {
  name = "data-load-trigger"
}

resource "google_cloudfunctions_function" "queue_time_func" {
  runtime     = "python310"
  name        = "get_queue_times_api_to_gcs"
  description = "Loads data from Queue Times API to GCS"

  available_memory_mb   = 128
  max_instances = 1
  timeout = 29
  source_archive_bucket = google_storage_bucket.function_code.name
  source_archive_object = google_storage_bucket_object.cloud_func_zip.name
  entry_point           = "pub_sub_trigger"
  environment_variables = {
    RAW_DATA_BUCKET = google_storage_bucket.raw_data.name
    
  }
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource = google_pubsub_topic.default.id
  }
}

resource "google_bigquery_dataset" "queue_times_stg" {
  dataset_id                  = "queue_times_stg"
  description                 = "This is dataset holds queue times for theme parks."
  location                    = "US"

  labels = {
    env = "dev"
  }
 access {
    role          = "OWNER"
    user_by_email = var.TF_SERVICE_ACCOUNT
 }
  access {
    user_by_email = "kendalldyke21@gmail.com"
    role   = "OWNER"
  }
}

resource "google_bigquery_table" "queue_times_stg" {
  dataset_id = google_bigquery_dataset.queue_times_stg.dataset_id
  table_id   = "queue_times_stg"
  deletion_protection = false
  external_data_configuration {
    autodetect    = true
    source_uris   = ["gs://${google_storage_bucket.raw_data.name}/*.json"]
    source_format = "NEWLINE_DELIMITED_JSON"
    schema = file("${path.module}/json/queue_times_stg.json")
    
  }
}

resource "google_cloud_scheduler_job" "queue_data_trigger" {
  name        = "trigger-queue-data-cf"
  description = "Triggers Queue Data Cloud Function via Pub/Sub Message"
  schedule    = "*/15 8-21 * * *"
  time_zone = "America/New_York"

  pubsub_target {
    topic_name = google_pubsub_topic.default.id
    data       = base64encode(var.PARK_LIST)
  }
}

# module "dataflow" {
#   source  = "terraform-google-modules/dataflow/google"
#   version = "2.2.0"
#   # insert the 6 required variables here
# }

# module "dataflow-job" {
#   source  = "terraform-google-modules/dataflow/google"
#   version = "0.1.0"

#   project_id  = var.PROJECT_ID
#   name = "wait-times-ingestion-stream"
#   on_delete = "cancel"
#   zone = "us-central1-a"
#   max_workers = 1
#   temp_gcs_location = "gs://wait-times-datflow-temp"
#   parameters = {

#   }
# }