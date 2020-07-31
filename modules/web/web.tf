
resource "aws_instance" "web" {
  ami           = "ami-06c119f12fa66b35b"
  instance_type = "t2.nano"
  subnet_id     = var.subnetc_id
  vpc_security_group_ids = [var.sg_id]
  count = var.servers
//  security_groups = [aws_security_group.allow_some.id]
  key_name = "OnPrem"
  tags          = {
    Name        = "web${count.index}"
    Environment = "production"
  }
  iam_instance_profile = aws_iam_instance_profile.web-profile.name
}

resource "aws_iam_role" "web_role" {
  name = "web_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "web-profile" {
  name = "web-profile"
  role = aws_iam_role.web_role.name
}

resource "aws_iam_policy_attachment" "web-admin-attachment" {
  name = "web-admin-attachment"
  policy_arn = aws_iam_policy.iam-admin-policy.arn
  roles = [aws_iam_role.web_role.name]
}

resource "aws_iam_policy" "iam-admin-policy" {
  name = "web-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
}


resource "aws_route53_record" "web" {
  count = var.servers
  name = "web${count.index}"
  type = "A"
  zone_id = var.route53_zoneid
  ttl = "6"
  records = [aws_instance.web[count.index].private_ip]
}