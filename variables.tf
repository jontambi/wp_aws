variable "aws_region" {
  default = "us-east-1"
  description = "Region 1 Ecommerce"
}

variable "http_port" {
  default = 80
}

variable "ssh_port" {
  default = 22
}

variable "https_port" {
  default = 443
}

data "aws_ami" "latest_wp" {
  owners = ["179966331834"]
  most_recent = true

  filter {
    name = "state"
    values = ["available"]
  }

  filter {
    name = "tag:Name"
    values = ["wp_img"]
  }
}

variable "ec2_type" {
  default = "t2.micro"
}

variable "available_zone" {
  default = "us-east-1a"
}