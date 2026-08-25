terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.6.0"
    }
  }
}

provider "google" {
  credentials = "./keys/my-creds.json"
  project     = "abrarsyed-bd-test"
  region      = "us-central1"
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = var.bq_dataset_name
  friendly_name               = "test"
  description                 = "this is created from terraform apply"
  location                    = "US"
  default_table_expiration_ms = 3600000

  labels = {
    env = "default"
  }

}
