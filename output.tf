output "tunnel1_ip" {
  value = aws_vpn_connection.main.tunnel1_address
}

output "tunnel1_key" {
  value = aws_vpn_connection.main.tunnel1_preshared_key
}

output "tunnel2_ip" {
  value = aws_vpn_connection.main.tunnel2_address
}

output "tunnel2_key" {
  value = aws_vpn_connection.main.tunnel2_preshared_key
}

output "instance_ip" {
  value = aws_instance.web.private_ip
}

