output "subneta_id" {
  value = aws_subnet.maina.id
}

output "subnetb_id" {
  value = aws_subnet.mainb.id
}

output "subnetc_id" {
  value = aws_subnet.mainc.id
}
//
//output "pubnetb_id" {
//  value = aws_subnet.pubmainb.id
//}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "route53_zoneid" {
  value = aws_route53_zone.private.id
}

output "sg_id" {
  value = aws_security_group.allow_some.id
}