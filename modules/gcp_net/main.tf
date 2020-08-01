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
  remote_traffic_selector = ["192.168.0.0/22"]

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
  auto_create_subnetworks = true
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


resource "google_compute_instance" "kube" {
  name         = "kube${count.index}"
  machine_type = "g1-small"
  count        = 1
  zone         = "us-west2-a"
  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }
 network_interface {
    network = google_compute_network.network1.name

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    foo = "bar"
    ssh-keys = "centos:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPvDlf6TZbThqrwrpGQD935NGv1rq4MchkSz7dC36iHxES5ou5WWJQJXCjUTOTEn3Dm9PhQTQCvmLyz1g9RCkRYBe4FRT08r5jsJRIzdvq1IqnQOGrhOMy9FLsG8n9u7Msf31SnYMXicpUrA4teFEnX2pAu3/e11fEVzsv6moHgEqmQiI4LCJuf2HBAgrSHA4lyKzj50o4tqRp1uBzQ0bjiGbUqBPeptWLMlmEf4HMlTyOQFQ1xuY3h07eLiuaN5gDgcxSUzLaK2eCrG+HGHyTT8DBrGkvgsyMwqjsEG+SkWP2zh5/SR/Rx2uBuMvjgk2g5RNXWCCzNFb360Kwjhax mamba@Williams-MacBook-Air-2.local"
  }

  metadata_startup_script = "echo hi > /test.txt"


}