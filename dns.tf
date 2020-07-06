resource "aws_route53_zone" "private" {
  name = "aws.gleich.tech"

  vpc {
    vpc_id = "${aws_vpc.main.id}"
  }
}

resource "aws_route53_record" "web" {
  name = "web"
  type = "A"
  zone_id = aws_route53_zone.private.id
  ttl = "6"
    records = [aws_instance.web.private_ip]

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
