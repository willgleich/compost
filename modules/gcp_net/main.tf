# Learn our public IP address
data "http" "ifconfig" {
   url = "http://ifconfig.io"
  request_headers = {
      User-Agent= "curl/7.64.1"
  }
}

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "!"
}


resource "google_compute_vpn_tunnel" "tunnel1" {
  name          = "tunnel1"
  peer_ip       = "${chomp(data.http.ifconfig.body)}"
  shared_secret = random_password.password.result

  target_vpn_gateway = google_compute_vpn_gateway.target_gateway.id
  local_traffic_selector = ["10.128.0.0/9"]
//  remote_traffic_selector = ["192.168.0.0/22"]
  remote_traffic_selector = ["0.0.0.0/0"]
//  local_traffic_selector = ["0.0.0.0/0"]
//  remote_traffic_selector = ["0.0.0.0/0"]

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]

provisioner "local-exec" {
  command = "ansible-playbook -e link1_key=${random_password.password.result}  -e link1_gateway=${google_compute_address.vpn_static_ip.address} -i ${path.root}/../opnsense/inventory.yaml ${path.root}/../opnsense/gcpvpn.yaml"
  }
}

resource "google_compute_vpn_gateway" "target_gateway" {
  name    = "vpn1"
  network = google_compute_network.network1.id
}

resource "google_compute_network" "network1" {
  name = "vpc"
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
  name          = "test-subnetwork"
  ip_cidr_range = "10.128.0.0/16"
  region        = "us-west3"
  network       = google_compute_network.network1.id
  private_ip_google_access = true
//  secondary_ip_range {
//    range_name    = "tf-test-secondary-range-update1"
//    ip_cidr_range = "192.168.10.0/24"
//  }
}

resource "google_compute_address" "vpn_static_ip" {
  name = "vpn-static-ip"
}

resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "fr-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.target_gateway.id
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.target_gateway.id
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.target_gateway.id
}

resource "google_compute_route" "route1" {
  name       = "route1"
  network    = google_compute_network.network1.name
  dest_range = "192.168.0.0/22"
  priority   = 1000

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel1.id
}

resource "google_compute_route" "route2" {
  name       = "route2"
  network    = google_compute_network.network1.name
  dest_range = "0.0.0.0/0"
  priority   = 1000

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel1.id
}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = google_compute_network.network1.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_ranges = ["192.168.0.0/22",  "${chomp(data.http.ifconfig.body)}"]
}

