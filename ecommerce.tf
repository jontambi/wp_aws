#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY EC2 WP INSTANCE
#This template runs WP on a EC2 Instance
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#REQUIRE A SPECIFIC TERRAFORM VERSION
#This module has been update with Terraform 0.12 syntax.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
    required_version = ">= 0.12"
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#AWS PROVIDER
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
provider "aws" {
  region = var.aws_region
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY VPC
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_vpc" "vpc_wp" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "VPC WP Instance"
  }
}

resource "aws_internet_gateway" "gateway_wp" {
  vpc_id = aws_vpc.vpc_wp.id
  tags = {
    Name = "Gateway WP"
  }
}

resource "aws_subnet" "subnet_wp" {
  cidr_block = "172.16.10.0/24"
  vpc_id = aws_vpc.vpc_wp.id
  availability_zone = var.available_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "wp_public_subnet"
  }
}

resource "aws_route_table" "default_route" {
  vpc_id = aws_vpc.vpc_wp.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway_wp.id
  }
  tags = {
    Name = "Public WP"
  }
}

resource "aws_route_table_association" "public_wp" {
  route_table_id = aws_route_table.default_route.id
  subnet_id = aws_subnet.subnet_wp.id
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY SECURITY GROUP
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_security_group" "security_wp" {
  name = "Security Group - WP"
  description = "Allow connection"
  vpc_id = aws_vpc.vpc_wp.id

  # Inbound SSH from anywhere
  ingress {
    from_port = var.ssh_port
    protocol = "tcp"
    to_port = var.ssh_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTP from anywhere
  ingress {
    from_port = var.http_port
    protocol = "tcp"
    to_port = var.http_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTPS from anywhere
  ingress {
    from_port = var.https_port
    protocol = "tcp"
    to_port = var.https_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY EC2 GitLab INSTANCE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_instance" "wp_server" {
  ami = data.aws_ami.latest_wp.id
  instance_type = var.ec2_type
  vpc_security_group_ids = [aws_security_group.security_wp.id]
#  key_name = aws_key_pair.ssh_default.key_name
  key_name = "bck_wp"
  availability_zone = var.available_zone
  subnet_id = aws_subnet.subnet_wp.id

  tags = {
    Name = "wp_server"
  }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create AWS Key Pair
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_key_pair" "ssh_default" {
    key_name = "wp_ssh"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAInFrdLJ6rf7cbIdMHL13ihZ+lA+7O7d/ZyehZ5ubpFnq7hJPXCVuya+Y7Nj5zNqdCW2JWd2BtpSagba9adLeOu9hmnMNC8E4hK6pLrGYPybaX/LNL6fco/GdCCHt1PjdAiPsj+oyh7KBSAI6/j3D0RDD7qTgL9P6cogvYbQwFOUkeG7m0v/ZvcUV6V1KN32KfBw4UuzBw5Qp4/L2LOqf7Ys9cX7jxsLvKYBWY7akmGfm9uYH/0OleSBV70A5FKs4O6ymDHTHTEaUBJxCTuqSRkwE0ZjFDimWXnHQJVj2blmS7f1XuaAohwaWF1ah2T4O79p9DMBcJIBVo5OaF6+l john@amaterasu"
}


