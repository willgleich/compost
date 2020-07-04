//data "aws_eks_cluster_auth" "cluster-auth" {
//  depends_on = [aws_eks_cluster.example]
//  name       = aws_eks_cluster.example.name
//}

provider "helm" {
  kubernetes {
    config_context = "arn:aws:eks:us-west-2:516873755856:cluster/example"
//    host                   = aws_eks_cluster.example.endpoint
//    cluster_ca_certificate = base64decode(aws_eks_cluster.example.certificate_authority.0.data)
//    token                  = data.aws_eks_cluster_auth.cluster-auth.token
//    load_config_file       = false
  }
}

provider "kubernetes" {
    config_context = "arn:aws:eks:us-west-2:516873755856:cluster/example"
}

resource "helm_release" "ingress" {
  chart = "nginx-ingress"
  repository = "https://kubernetes-charts.storage.googleapis.com"
  name = "ingress"
      values = [
    "${file("ingress-nginx.yaml")}"
  ]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}
resource "helm_release" "prom" {
  chart = "prometheus-operator"
  repository = "https://kubernetes-charts.storage.googleapis.com"
  name = "prom"
  namespace = "monitoring"

    values = [
    "${file("prom-values.yaml")}"
  ]
}