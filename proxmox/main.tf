provider "proxmox" {
  pm_api_url = "https://192.168.2.11:8006/api2/json"
  pm_user = "root@pam"
  pm_tls_insecure = true
}

terraform {
  backend "consul" {
    address = "consul.gleich.tech"
    scheme  = "https"
    path    = "tf/proxmox"
  }
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.6.8"
    }
  }
}


resource "proxmox_vm_qemu" "resource-name" {
  name = "centos-test"
  target_node = "mox01"
//  iso = "ISO file name"
  # or
  clone = "cent00"
}
