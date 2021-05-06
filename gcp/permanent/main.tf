provider "google" {
  credentials = "../main.json"

  project = "main-285019"
  region  = "us-west3"
}

terraform {
  backend "gcs" {
    bucket = "gleich-infra"
    prefix =  "tf/gke/permanent"
  }
}

data "google_project" "project" {}



module "gcs_buckets" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 1.7"
  project_id  = data.google_project.project.project_id
  names = ["gleich-vault"]
  prefix = ""
  set_admin_roles = true
  storage_class = "STANDARD"
  admins = ["user:wgleich@gmail.com", "serviceAccount:${google_service_account.vault_account.email}"]
  location = "us-west3"
//  versioning = {
//    first = true
//  }
//  bucket_admins = {
//    second = "user:spam@example.com,eggs@example.com"
//  }
}

resource "google_service_account" "vault_account" {
  account_id   = "gleich-vault"
  display_name = "Vault SA for gcs"
}


resource "google_service_account_key" "mykey" {
  service_account_id = google_service_account.vault_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}


output "test" {
  value = google_service_account_key.mykey.private_key
//  value = google_service_account.vault_account
}