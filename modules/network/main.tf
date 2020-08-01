
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
  enable_dns_support = true
  enable_dns_hostnames = true
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

resource "aws_security_group" "allow_some" {
  name        = "allow_some"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "all from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
//      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "all from OnPrem"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
      cidr_blocks = ["192.168.0.0/22"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_some"
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
  command = "ansible-playbook -e remote_ip=10.0.1.205 -e link1_key=${aws_vpn_connection.main.tunnel1_preshared_key} -e link2_key=${aws_vpn_connection.main.tunnel2_preshared_key} -e link1_gateway=${aws_vpn_connection.main.tunnel1_address} -e link2_gateway=${aws_vpn_connection.main.tunnel2_address} -i ${path.root}/opnsense/inventory.yaml ${path.root}//opnsense/awsvpn.yaml"
  }

//provisioner "local-exec" {
//  command = "ansible-playbook -i ${path.root}/opnsense/inventory.yaml ${path.root}/opnsense/deactivate-ipsec.yaml"
//  when    = "destroy"
// }
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


resource "aws_route53_zone" "private" {
  name = "aws.gleich.tech"

  vpc {
    vpc_id = "${aws_vpc.main.id}"
  }
}



resource "aws_route53_resolver_endpoint" "opn-in" {
  direction = "INBOUND"
  security_group_ids = [aws_security_group.allow_some.id]
  name = "inbound-ep"
    ip_address {
        ip        = "10.0.1.205"
        subnet_id = aws_subnet.maina.id
    }
    ip_address {
        ip        = "10.0.2.10"
        subnet_id = aws_subnet.mainb.id
    }

}


resource "aws_route53_resolver_endpoint" "opn-out" {
  direction = "OUTBOUND"
  security_group_ids = [aws_security_group.allow_some.id]
  name = "outbound-ep"
    ip_address {
//        ip        = "10.0.2.173"
        subnet_id = aws_subnet.mainb.id
    }
    ip_address {
//        ip        = "10.0.3.105"
        subnet_id = aws_subnet.mainc.id
    }

}

resource "aws_route53_resolver_rule" "fwd" {
  domain_name          = "gleich.tech"
  name                 = "fwd to opnsense"
  rule_type            = "FORWARD"
  resolver_endpoint_id = "${aws_route53_resolver_endpoint.opn-out.id}"

  target_ip {
    ip = "192.168.1.1"
  }

}

resource "aws_route53_resolver_rule_association" "outbound-dns" {
  resolver_rule_id = aws_route53_resolver_rule.fwd.id
  vpc_id = aws_vpc.main.id
}


