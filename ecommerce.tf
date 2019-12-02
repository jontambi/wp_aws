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
    from_port = var.ftp_port
    protocol = "tcp"
    to_port = var.ftp_port
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
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4en3e08Qqt5W83DH9Ln2v9VKG5QLK/w8/4nAbUCNGmBXfQxjq2xrVijTWIuLHh850Nc6KhLHnOqDpTe96a0HqffkKGXpmlm+X94cM1IOikbjalwP+u9MA55hyeIz5EnRfx0zoLJuYTFLIP23JZtQ+NPI557XqMKsSmfur7UTtwHKQPaetn5du7SK+Ztxd/O0/2IEU139B2C2VMCdTBNNUGTpig5D1vR1QKvZng4kNEB34Ey23WCPpxKqO9HMqybRlJ6iLkeL65s31Gh6w5UCySNKbUX1jJpO/zmHHwxpl+Xb08e8wjesaMndsPM1QpWNhAS/1BzRJ7pYsGOYYWPB3 john@amaterasu"
}
