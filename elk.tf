resource "aws_security_group" "nordcloud_elk_sg" {
  name   = "nordcloud-elk-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticsearch_domain" "nordcloud-es" {
  domain_name           = "nordcloud-elk"
  elasticsearch_version = "7.1"

  cluster_config {
    instance_count = 2

    instance_type = var.elk_instance_type

    zone_awareness_enabled = true

    zone_awareness_config {
      availability_zone_count = 2
    }
  }

  vpc_options {
    subnet_ids = [
      module.vpc.public_subnets[0],
      module.vpc.public_subnets[1]
    ]

    security_group_ids = [
      aws_security_group.nordcloud_elk_sg.id
    ]
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "es:*",
          "Principal": "*",
          "Effect": "Allow",
          "Resource": "arn:aws:*"
      }
  ]
}
  CONFIG

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags = {
    Domain = "nordcloud-elk-sg"
  }
}