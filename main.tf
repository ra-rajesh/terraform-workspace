terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region_name
}

# Configure the AWS S3 under rajesh_rajendiran
terraform {
  backend "s3" {
    bucket = "terra-task"
    key    = "workspace"
    region = "us-east-1"
  }
}

# Configure the AWS VPC
resource "aws_vpc" "Vpc_Terraform" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = var.vpc_instance_tenancy
  enable_dns_hostnames = var.vpc_enable_dns_hostnames
  enable_dns_support   = var.vpc_enable_dns_support

  tags = {
    Name = var.vpc_name
  }
}

# Configure the AWS VPC Subnet 
resource "aws_subnet" "Vpc_Pub_Subnet_Terraform" {
  vpc_id            = aws_vpc.Vpc_Terraform.id
  cidr_block        = var.pub1_subnet_cidr_block
  availability_zone = var.pub1_sn_availability_zone
  #map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name = var.vpc_pub1_sn_name
  }
}

# Configure the AWS VPC IGW
resource "aws_internet_gateway" "IGW_Terraform" {
  vpc_id = aws_vpc.Vpc_Terraform.id

  tags = {
    Name = var.vpc_igw_name
  }
}

# Configure the AWS VPC RT
resource "aws_route_table" "Routetable_Terraform" {
  vpc_id = aws_vpc.Vpc_Terraform.id

  route {
    cidr_block = var.rt_cidr_block
    gateway_id = aws_internet_gateway.IGW_Terraform.id
  }
  #   route {
  #     ipv6_cidr_block        = "::/0"
  #     egress_only_gateway_id = aws_egress_only_internet_gateway.EgressOnlyGateway_Terraform.id
  #   }

  tags = {
    Name = var.Pub1_routetable_name
  }
}

# Configure the AWS VPC RTA
resource "aws_route_table_association" "Routetable_Association_Terraform" {
  subnet_id      = aws_subnet.Vpc_Pub_Subnet_Terraform.id
  route_table_id = aws_route_table.Routetable_Terraform.id
}

# Configure the AWS Security Group
resource "aws_security_group" "Sg_Terraform" {
  name        = "Sg_Terraform"
  description = "Security group allowing SSH, HTTP, and HTTPS"
  vpc_id      = aws_vpc.Vpc_Terraform.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.Sg_name
  }
}

# Instance
resource "aws_instance" "Terraform_Pub" {
  ami                         = var.ec2_ami_name
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.Vpc_Pub_Subnet_Terraform.id
  key_name                    = var.ec2_key_name
  vpc_security_group_ids      = [aws_security_group.Sg_Terraform.id]
  associate_public_ip_address = var.ec2_associate_public_ip_address
  availability_zone           = var.ec2_availability_zone

  tags = {
    Name        = var.ec2_name
    Owner       = "Rajesh"
    Environment = "Development"
  }

}
