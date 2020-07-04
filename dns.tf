resource "aws_route53_zone" "private" {
  name = "aws.gleich.tech"

  vpc {
    vpc_id = "${aws_vpc.main.id}"
  }
}