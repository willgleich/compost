data "aws_eks_cluster_auth" "cluster-auth" {
  depends_on = [aws_eks_cluster.example]
  name       = aws_eks_cluster.example.name
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.example.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.example.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster-auth.token
    load_config_file       = false
  }
}

resource "helm_release" "ingress" {
  chart = "nginx-ingress"
  repository = "https://kubernetes-charts.storage.googleapis.com"
  name = "ingress"
}