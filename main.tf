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
  servers = 1
  source = "./modules/web"
//  index = count.index
  route53_zoneid = module.net.route53_zoneid
  sg_id = module.net.sg_id
  subnetc_id =  module.net.subnetc_id
}


module "eks" {
  count = 0
  source = "./modules/eks_mod"
  pubnetb_id = module.net.pubnetb_id
  subneta_id = module.net.subneta_id
  subnetb_id = module.net.subnetb_id
  subnetc_id = module.net.subnetc_id
  vpc_id = module.net.vpc_id
}

output "public_ip" {
  value = module.web.ip
}