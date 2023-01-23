terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {}

data "aws_region" "current" {
  
}

data "aws_ami" "nats-server" {
  most_recent = true

  owners = ["self"]
  tags = {
    Name = "nats-server"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_subnets" "target" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

data "aws_vpc" "provided" {
  count = local.create_vpc ? 0 : 1
  id    = var.vpc_id
}

data "template_file" "init" {
  count    = var.server_count
  template = file("${path.module}/init.tpl")
  vars = {
    SERVER_INDEX = "${count.index}"
    SERVER_REGION = "${data.aws_region.current.name}"
  }
}

locals {
  create_vpc = var.vpc_id != null ? false : true
  vpc_id     = local.create_vpc ? module.vpc.vpc_id : data.aws_vpc.provided[0].id
}

resource "random_id" "index" {
  byte_length = 2
}

resource "aws_security_group" "nats-ingress" {
  name        = "nats-server-ingress"
  description = "Allow inbound nats ports"
  vpc_id      = local.vpc_id

  ingress {
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "nats-server port"
    from_port        = 4222
    to_port          = 4222
    protocol         = "tcp"
  }

  ingress {
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "nats-monitor port"
    from_port        = 8222
    to_port          = 8222
    protocol         = "tcp"
  }

  ingress {
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "nats-cluster port"
    from_port        = 4248
    to_port          = 4248
    protocol         = "tcp"
  }

  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_policy" "list-ec2-instances" {
  name        = "list-ec2-instances"
  description = "Provide nats servers the ability to find others on boot"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "ec2:Describe*"
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}


resource "aws_iam_role" "nats-server" {
  name = "nats-server-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "RoleForEC2"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "nats-server" {
  name       = "nats-server-attachment"
  roles      = [aws_iam_role.nats-server.name]
  policy_arn = aws_iam_policy.list-ec2-instances.arn
}

resource "aws_iam_instance_profile" "nats-server" {
  name = "nats-server-instace-profile"
  role = aws_iam_role.nats-server.name
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  create_vpc = local.create_vpc

  name = "nats-server-vpc"
  cidr = "10.0.0.0/16"
  azs  = data.aws_availability_zones.available.names
  public_subnets = [
    for net in range(0, length(data.aws_availability_zones.available.names)) : cidrsubnet("10.0.0.0/16", 8, net)
  ]
  enable_dns_hostnames = true

  vpc_tags = {
    Name = "nats-server"
  }
}

resource "aws_instance" "nats-server" {
  count                  = var.server_count
  ami                    = data.aws_ami.nats-server.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.target.ids[random_id.index.dec % length(data.aws_subnets.target.ids)]
  vpc_security_group_ids = [resource.aws_security_group.nats-ingress.id]
  iam_instance_profile   = aws_iam_instance_profile.nats-server.name
  lifecycle {
    ignore_changes = [subnet_id]
  }
  tags = {
    Name             = "nats-server"
    TF_DEPLOYED_NATS = "nats${count.index}"
  }
  user_data = data.template_file.init[count.index].rendered
}