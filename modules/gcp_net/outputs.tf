//output "vpn1" {
//  value = google_compute_vpn_tunnel.tunnel1.shared_secret
//}

output "network_name" {
  value = google_compute_network.network1.name
}

output "subnet_name" {
  value = google_compute_subnetwork.net-a.self_link
}