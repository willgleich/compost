# Learn our public IP address
data "http" "ifconfig" {
   url = "http://ifconfig.io"
  request_headers = {
      User-Agent= "curl/7.64.1"
  }
}

resource "random_password" "password" {
  length = 36
  special = true
  override_special = "!"
}


resource "google_compute_vpn_tunnel" "tunnel1" {
  name          = "tunnel1"
  peer_ip       = "${chomp(data.http.ifconfig.body)}"
  shared_secret = random_password.password.result

  target_vpn_gateway = google_compute_vpn_gateway.target_gateway.id
  local_traffic_selector = ["0.0.0.0/0"]
//  local_traffic_selector = ["10.128.0.0/9"]
//  remote_traffic_selector = ["192.168.0.0/22"]
  remote_traffic_selector = ["0.0.0.0/0"]

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
  name = var.vpc_name
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "net-a" {
  name          = "${var.vpc_name}-subnet-a"
  ip_cidr_range = "10.128.0.0/20"
  region        = "us-west3"
  network       = google_compute_network.network1.id
  private_ip_google_access = true
#  secondary_ip_range {
#    range_name    = "secondary-range"
#    ip_cidr_range = "192.168.10.0/24"
#  }
}
#
#resource "google_compute_subnetwork" "netb" {
#  name          = "${var.vpc_name}-subnet"
#  ip_cidr_range = "10.128.0.0/16"
#  region        = "us-west3-a"
#  network       = google_compute_network.network1.id
#  private_ip_google_access = true
#  //  secondary_ip_range {
#  //    range_name    = "tf-test-secondary-range-update1"
#  //    ip_cidr_range = "192.168.10.0/24"
#  //  }
#}

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



//resource "google_compute_route" "route1" {
//  name       = "localroute"
//  network    = google_compute_network.network1.name
//  dest_range = "10.128.0.0/16"
//  priority   = 0
////  next_hop_network = google_compute_network.network1.id
//  tags = ["onprem-nat"]
//}


resource "google_compute_route" "route2" {
  name       = "internet-route"
  network    = google_compute_network.network1.name
  dest_range = "0.0.0.0/0"
  priority   = 1000
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel1.id
//  tags = ["onprem-nat"]
}


//
//resource "google_compute_route" "route2" {
//  name       = "internet-route"
//  network    = google_compute_network.network1.name
//  dest_range = "0.0.0.0/0"
//  priority   = 1000
//  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel1.id
//  tags = ["onprem-nat"]
//}

resource "google_compute_route" "route3" {
  name       = "onprem-route"
  network    = google_compute_network.network1.name
  dest_range = "192.168.0.0/20"
  priority   = 1000
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel1.id
//  tags = ["onprem-nat"]
}

resource "google_compute_route" "route4" {
  name       = "onprem2-route"
  network    = google_compute_network.network1.name
  dest_range = "10.0.0.0/16"
  priority   = 1000
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel1.id
//  tags = ["onprem-nat"]
}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = google_compute_network.network1.name
  enable_logging = true
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_ranges = ["192.168.0.0/22",  "${chomp(data.http.ifconfig.body)}", "10.0.0.0/16"]
}

resource "google_compute_firewall" "egress" {
  name    = "test-egress-firewall"
  network = google_compute_network.network1.name
  enable_logging = true
  direction = "EGRESS"
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  destination_ranges = ["0.0.0.0/0"]
}

#resource "google_compute_global_address" "private_ip_alloc" {
#  name          = "private-ip-alloc"
#  purpose       = "VPC_PEERING"
#  address_type  = "INTERNAL"
#  prefix_length = 16
#  network       = google_compute_network.network1.id
#}
#
#resource "google_service_networking_connection" "foobar" {
#  network                 = google_compute_network.network1.id
#  service                 = "storage.googleapis.com"
#  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
#}


resource "google_compute_global_address" "default" {
#  provider      = google-beta
  project       = google_compute_network.network1.project
  name          = "global-psconnect-ip"
  address_type  = "INTERNAL"
  purpose       = "PRIVATE_SERVICE_CONNECT"
  network       = google_compute_network.network1.id
  address       = "10.128.255.6"

  depends_on = [google_compute_subnetwork.net-a]
}

resource "google_compute_global_forwarding_rule" "default" {
#  provider      = google-beta
  project       = google_compute_network.network1.project
  name          = "globalrule"
  target        = "all-apis"
  network       = google_compute_network.network1.id
  ip_address    = google_compute_global_address.default.id
  load_balancing_scheme = ""
  depends_on = [google_compute_subnetwork.net-a]
}

resource "google_dns_managed_zone" "example-zone" {
  name        = "example-zone"
  dns_name    = "googleapis.com."
  description = "Example DNS zone"

  visibility = "private"
  private_visibility_config {
    networks {
      network_url = google_compute_network.network1.id
    }
  }

  }

resource "google_dns_record_set" "endpoint" {
  managed_zone = google_dns_managed_zone.example-zone.name
  name         = "googleapis.com."
  type         = "A"
  rrdatas = [google_compute_global_address.default.address]
}

resource "google_dns_record_set" "wildcard" {
  managed_zone = google_dns_managed_zone.example-zone.name
  name         = "*.googleapis.com."
  type         = "CNAME"
  rrdatas = ["googleapis.com."]
}

