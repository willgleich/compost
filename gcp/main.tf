provider "google" {
  credentials = "main.json"

  project = "main-285019"
  region  = "us-west3"
}

terraform {
  backend "consul" {
    address = "consul.gleich.tech"
    scheme  = "https"
    path    = "tf/gke/network"
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
  zone         = "us-west3-a"
  tags = ["onprem-nat"]

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