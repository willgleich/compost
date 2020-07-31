//
//resource "aws_iam_role" "example" {
//  name = "eks-cluster-example"
//
//  assume_role_policy = <<POLICY
//{
//  "Version": "2012-10-17",
//  "Statement": [
//    {
//      "Effect": "Allow",
//      "Principal": {
//        "Service": "eks.amazonaws.com"
//      },
//      "Action": "sts:AssumeRole"
//    }
//  ]
//}
//POLICY
//}
//
//resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
//  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
//  role       = "${aws_iam_role.example.name}"
//}
//
//resource "aws_iam_role_policy_attachment" "example-AmazonEKSServicePolicy" {
//  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
//  role       = "${aws_iam_role.example.name}"
//}
//
//resource "aws_eks_cluster" "example" {
//  name     = "example"
//  role_arn = "${aws_iam_role.example.arn}"
//
//  vpc_config {
//    subnet_ids = ["${module.net.subneta_id}", "${module.net.subnetb_id}", "${module.net.subnetc_id}", module.net.pubnetb_id]
//    endpoint_public_access = false
//    endpoint_private_access = true
//    security_group_ids = [aws_security_group.cluster-sg.id]
//  }
//
//  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
//  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
//  depends_on = [
//    "aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy",
//    "aws_iam_role_policy_attachment.example-AmazonEKSServicePolicy",
//  ]
//
////  provisioner "local-exec" {
////    command = "bash eks-dns.sh ${aws_eks_cluster.example.name} default"
////
////  }
//}
//
//output "endpoint" {
//  value = "${aws_eks_cluster.example.endpoint}"
//}
//
//output "kubeconfig-certificate-authority-data" {
//  value = "${aws_eks_cluster.example.certificate_authority.0.data}"
//}
//
//
//resource "aws_eks_node_group" "example" {
//  cluster_name    = aws_eks_cluster.example.name
//  node_group_name = "example"
//  node_role_arn   = aws_iam_role.example1.arn
//  subnet_ids      = [module.net.subneta_id,module.net.subnetb_id,module.net.subnetc_id]
//
//         remote_access {
//           ec2_ssh_key               = "OnPrem"
//        }
//  scaling_config {
//    desired_size = 1
//    max_size     = 1
//    min_size     = 1
//  }
//
//  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
//  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
//  depends_on = [
//    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
//    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
//    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
//    aws_eks_cluster.example
//  ]
//}
//
//
//resource "aws_iam_role" "example1" {
//  name = "eks-node-group-example"
//
//  assume_role_policy = jsonencode({
//    Statement = [{
//      Action = "sts:AssumeRole"
//      Effect = "Allow"
//      Principal = {
//        Service = "ec2.amazonaws.com"
//      }
//    }]
//    Version = "2012-10-17"
//  })
//}
//
//resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
//  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
//  role       = aws_iam_role.example1.name
//}
//
//resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
//  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
//  role       = aws_iam_role.example1.name
//}
//
//resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
//  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
//  role       = aws_iam_role.example1.name
//}
//
//#Security Group
//resource "aws_security_group" "cluster-sg" {
//  name        = "clusterSG"
//  description = "Cluster communication with worker nodes"
//  vpc_id      =  module.net.vpc_id
//  egress {
//    from_port   = 0
//    to_port     = 0
//    protocol    = "-1"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  tags = {
//    Name = "cluster"
//  }
//}
//
//resource "aws_security_group_rule" "cluster-ingress-workstation-https" {
//  cidr_blocks       = ["192.168.0.0/22"]
//  description       = "Allow workstation to communicate with the cluster API Server"
//  from_port         = 443
//  protocol          = "tcp"
//  security_group_id = "${aws_security_group.cluster-sg.id}"
//  to_port           = 443
//  type              = "ingress"
//}
