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

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY GATEWAY
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_internet_gateway" "gateway_wp" {
  vpc_id = aws_vpc.vpc_wp.id
  tags = {
    Name = "Gateway WP"
  }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY SUBNET
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_subnet" "subnet_wp" {
  cidr_block = "172.16.10.0/24"
  vpc_id = aws_vpc.vpc_wp.id
  availability_zone = var.available_zone

  tags = {
    Name = "wp_public_subnet"
  }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY ROUTE TABLE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY ROUTE TABLE ASSOCIATION
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
  ingress {
    from_port = 21
    protocol = "tcp"
    to_port = 21
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
#DEPLOY AWS ROUTE53 ZONE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_route53_zone" "route53_wp" {
  name = "matiswoodenplanet.com"
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY AWS ROUTE53 RECORD
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_route53_record" "www_wp" {
  name = "www.matiswoodenplanet.com"
  type = "A"
  zone_id = aws_route53_zone.route53_wp.id
  ttl = 300
  records = [aws_eip.elasticip_wp.public_ip]
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY EC2 WP INSTANCE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_instance" "wp_server" {
  ami = data.aws_ami.latest_wp.id
  instance_type = var.ec2_type
  vpc_security_group_ids = [aws_security_group.security_wp.id]
  key_name = aws_key_pair.ssh_default.key_name
  availability_zone = var.available_zone
  subnet_id = aws_subnet.subnet_wp.id

  tags = {
    Name = "wp_server"
  }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY ASSOCIATION EIP - INTANCE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_eip_association" "associationip_wp" {
  instance_id = aws_instance.wp_server.id
  allocation_id = aws_eip.elasticip_wp.id
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY ELASTIC IP
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_eip" "elasticip_wp" {
  vpc = true
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create AWS Key Pair
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_key_pair" "ssh_default" {
    key_name = "wp_ssh"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCq84AasNpR+8OPuLPqrJ6lVNUayqdrNuBHJk/yZNS1/gDr1iY7wlJsLi7bjLW2X6sw/X+cAMIhOY0MqmZyAHRSrcoO6aKHydlCYN77Hl8SxeORA51coAV5DkH7BmB3pBpxP0Q+gAL6ypOwIMsDzAUU0FDAjMV+oFEATa3oKkU24EmLyE91Nok9w53I/1N8YBXYPt2Tz7OB93MeJqTdsiQ5r5+uAUrgu8NDgRhvFEG0jx5FPJ3knJhmDrl0ogi4bgQ/xbFN6uy2ZwowXqAXImPUZ1Gpahg9U/Ycg58CYnwB3RX1pWB+OdBib8sjjz07+tB06JTOpoAl3mXLEz7q1oRNe2/bPPlO64c1R2GCIl5vzqLCfuVdWWsEMu0e7Db5WXVvK8yb2k3c4jv2MrKiqJ8npHoDvbm41kuHOipWRBbPIu5wi9+V3zBkO2rW0u8nLNH5SR0RHEdnESqNHFbyj6XagB3+qlgWxY2feSMlIcOBIgj6MYDJ6YR0qq6r4D+l268= aws_terraform_ssh_key"
}


