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

# Learn our public IP address
data "http" "ifconfig" {
   url = "http://ifconfig.io"
  request_headers = {
      User-Agent= "curl/7.64.1"
  }
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  # instance_tenancy = "dedicated"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "maina" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "Main"
   "kubernetes.io/cluster/example" = "shared"
  }
}

resource "aws_subnet" "mainb" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "Main"
    "kubernetes.io/cluster/example" = "shared"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-06c119f12fa66b35b"
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.mainb.id
  vpc_security_group_ids = [aws_security_group.allow_all.id]
//  security_groups = [aws_security_group.allow_all.id]
  key_name = "OnPrem"
  tags = {
    Name = "HelloWorld"
  }
}




resource "aws_subnet" "mainc" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2c"

  tags = {
    Name = "Main"
    "kubernetes.io/cluster/example" = "shared"

  }

}

resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = "${chomp(data.http.ifconfig.body)}"
  type       = "ipsec.1"

  tags = {
    Name = "main-customer-gateway"
  }
}


resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "main"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "all from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
//    cidr_blocks = [aws_vpc.main.cidr_block]
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all"
  }
}

resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = "${aws_vpn_gateway.vpn_gw.id}"
  customer_gateway_id = "${aws_customer_gateway.main.id}"
  type                = "ipsec.1"
  static_routes_only  = true

  tags  = {
          "Name" = "OPNsense"
        }

provisioner "local-exec" {
  command = "ansible-playbook -e remote_ip=${aws_instance.web.private_ip} -e link1_key=${aws_vpn_connection.main.tunnel1_preshared_key} -e link2_key=${aws_vpn_connection.main.tunnel2_preshared_key} -e link1_gateway=${aws_vpn_connection.main.tunnel1_address} -e link2_gateway=${aws_vpn_connection.main.tunnel2_address} -i opnsense/inventory.yaml opnsense/xml-book.yaml"
  }
}


resource "aws_vpn_gateway_route_propagation" "example" {
  vpn_gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
  route_table_id = "${aws_vpc.main.default_route_table_id}"
}


resource "aws_vpn_connection_route" "the_lab" {
  destination_cidr_block = "192.168.0.0/22"
  vpn_connection_id      = "${aws_vpn_connection.main.id}"
}



//output "public_ip" {
//  value = "${chomp(data.http.ifconfig.body)}"
//}