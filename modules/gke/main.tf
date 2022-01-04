resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account"
}

variable "network_name" {
  default = ""
}


variable "subnet_name" {
  default = ""
}

variable "cluster_name" {
  default = "cluster1"
}


resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"
  location = "us-west3-c"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = false
  initial_node_count       = 1
  networking_mode = "VPC_NATIVE"
  network = var.network_name
  subnetwork = var.subnet_name
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "192.168.0.0/22"
    }
    cidr_blocks {
      cidr_block = "10.128.0.0/16"
    }
  }
  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes = true
    master_ipv4_cidr_block = "10.128.16.0/28"
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block = "172.16.0.0/16"

  }
}

resource "google_compute_network_peering_routes_config" "peering" {
  export_custom_routes = true
  import_custom_routes = false
  network              = var.network_name
  peering              = google_container_cluster.primary.private_cluster_config[0].peering_name

  depends_on = [google_container_cluster.primary]
}

#resource "google_container_node_pool" "primary_preemptible_nodes" {
#  name       = "my-node-pool"
#  location   = "us-west3-c"
#  cluster    = google_container_cluster.primary.name
#  node_count = 1
#
#  node_config {
#    preemptible  = true
#    machine_type = "e2-medium"
#
#    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
#    service_account = google_service_account.default.email
#    oauth_scopes    = [
#      "https://www.googleapis.com/auth/cloud-platform"
#    ]
#  }
#}