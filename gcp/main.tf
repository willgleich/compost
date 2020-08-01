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