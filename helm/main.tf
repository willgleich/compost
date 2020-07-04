provider "aws" {
  profile    = "default"
  region     = "us-west-2"
}

terraform {
  backend "consul" {
    address = "consul.gleich.tech"
    scheme  = "https"
    path    = "tf/aws/helm"
  }
}


