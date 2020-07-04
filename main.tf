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
//   "kubernetes.io/cluster/example" = "shared"
  }
}

resource "aws_subnet" "mainb" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "Main"
    #TODO: Remove the hard tag here.
//    "kubernetes.io/cluster/example" = "shared"
  }
}

resource "aws_subnet" "mainc" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2c"

  tags = {
    Name = "Main"
//    "kubernetes.io/cluster/${aws_eks_cluster.name}" = "shared"
  }
}
//resource "aws_subnet" "pubmaina" {
//  vpc_id     = "${aws_vpc.main.id}"
//  cidr_block = "10.0.101.0/24"
//  availability_zone = "us-west-2a"
//
//  tags = {
//    Name = "PubMain2a"
//  }
//}

resource "aws_subnet" "pubmainb" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.102.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "PubMain2b"
    "kubernetes.io/role/elb" = "1"
  }
}
//
//resource "aws_subnet" "pubmainc" {
//  vpc_id     = "${aws_vpc.main.id}"
//  cidr_block = "10.0.103.0/24"
//  availability_zone = "us-west-2c"
//
//  tags = {
//    Name = "PubMain2c"
//  }
//}



resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = "${chomp(data.http.ifconfig.body)}"
  type       = "ipsec.1"

  tags = {
    Name = "main-customer-gateway"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id  = aws_vpc.main.id
}
//
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.pubmainb.id}"
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

provisioner "local-exec" {
  command = "ansible-playbook -i opnsense/inventory.yaml opnsense/deactivate-ipsec.yaml"
  when    = "destroy"
 }
}



resource "aws_vpn_gateway_route_propagation" "example" {
  vpn_gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
  route_table_id = "${aws_vpc.main.default_route_table_id}"

  depends_on = [aws_vpn_connection.main]
}

resource "aws_route" "nat_gateway" {
  route_table_id = "${aws_vpc.main.default_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.gw.id
}
//resource "aws_default_route_table" "default" {
//  default_route_table_id = "${aws_vpc.main.default_route_table_id}"
//
//  route {
//    cidr_block = "0.0.0.0/0"
//    nat_gateway_id = aws_nat_gateway.gw.id
//  }
//
//  tags = {
//    Name = "default table"
//  }
//}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }


  tags = {
    Name = "Public to IG"
  }
}

resource "aws_route_table_association" "r" {
  route_table_id = "${aws_route_table.r.id}"
  subnet_id = aws_subnet.pubmainb.id
}

resource "aws_vpn_connection_route" "the_lab" {
  destination_cidr_block = "192.168.0.0/22"
  vpn_connection_id      = "${aws_vpn_connection.main.id}"
}



resource "aws_instance" "web" {
  ami           = "ami-06c119f12fa66b35b"
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.mainc.id
  vpc_security_group_ids = [aws_security_group.allow_all.id]
//  security_groups = [aws_security_group.allow_all.id]
  key_name = "OnPrem"
  tags = {
    Name = "HelloWorld"
  }
  depends_on = ["aws_internet_gateway.gw"]
}



//output "public_ip" {
//  value = "${chomp(data.http.ifconfig.body)}"
//}