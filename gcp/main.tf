provider "google" {
  credentials = "/Users/will/.gcloud/main-285019-d0558d0d5b74.json"

  project = "main-285019"
  region  = "us-west3"
}

terraform {
    backend "gcs" {
      bucket = "gleich-infra"
      prefix =  "tf/gke/network"
    }
}

module "net" {
  source = "../modules/gcp_net"
}


resource "google_compute_instance" "web" {
  name         = "web"
//    name         = "web${count.index}"
  machine_type = "g1-small"
//  count        = 1
  zone         = "us-west3-c"
  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }
 network_interface {
    network = module.net.network_name
    subnetwork = module.net.subnet_name
//    access_config {
//      // Ephemeral IP
//    }
  }

  metadata = {
    foo = "bar"
  }

  metadata_startup_script = "echo hi > /test.txt"


}

output "ip" {
  value = google_compute_instance.web.network_interface
}
