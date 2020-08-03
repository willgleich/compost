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
    ssh-keys = "centos:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPvDlf6TZbThqrwrpGQD935NGv1rq4MchkSz7dC36iHxES5ou5WWJQJXCjUTOTEn3Dm9PhQTQCvmLyz1g9RCkRYBe4FRT08r5jsJRIzdvq1IqnQOGrhOMy9FLsG8n9u7Msf31SnYMXicpUrA4teFEnX2pAu3/e11fEVzsv6moHgEqmQiI4LCJuf2HBAgrSHA4lyKzj50o4tqRp1uBzQ0bjiGbUqBPeptWLMlmEf4HMlTyOQFQ1xuY3h07eLiuaN5gDgcxSUzLaK2eCrG+HGHyTT8DBrGkvgsyMwqjsEG+SkWP2zh5/SR/Rx2uBuMvjgk2g5RNXWCCzNFb360Kwjhax mamba@Williams-MacBook-Air-2.local"
  }

  metadata_startup_script = "echo hi > /test.txt"


}

output "ip" {
  value = google_compute_instance.web.network_interface
}