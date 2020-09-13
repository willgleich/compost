provider "aws" {
  profile    = "default"
  region     = "us-west-2"
}

terraform {
  backend "consul" {
    address = "consul.gleich.tech"
    scheme  = "https"
    path    = "tf/aws/network"
  }
}

module "net" {
  source = "./modules/network"
}

module "web" {
  servers = 0
  source = "./modules/web"
//  index = count.index
  route53_zoneid = module.net.route53_zoneid
  sg_id = module.net.sg_id
  subnetc_id =  module.net.subnetc_id
}

//output "public_ip" {
//  value = "${chomp(data.http.ifconfig.body)}"
//}