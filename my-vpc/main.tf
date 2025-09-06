provider "aws" {
  region = "us-east-1"
  profile = "avner"
  
  default_tags {
    tags = {
      project-relation = "VPC-TESTS"
      created-by       = "Avner Tzur"
      requested-by     = "avner.zur@gmail.com"
      environment-type = "dev"
      environment-name = "development"
      jira-tickets     = "THP-1234"
    }
  } # Default region, can be changed as needed # Default region, can be changed as needed
}

terraform {
  backend "s3" {
    bucket         = "my-vpc-tfstate"
    key            = "my-vps-terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-vpc-tfstate-lock"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "my-vpc"
  }
}

# Internet Gateway for external subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# External subnets in two AZs
resource "aws_subnet" "external" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 2, count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "external-subnet-${count.index + 1}"
  }
}

# NAT Gateway for internal subnets (requires Elastic IP)
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.external[0].id # Place in first external subnet
  tags = {
    Name = "main-nat-gw"
  }
}

# Internal subnets in two AZs
resource "aws_subnet" "internal" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 2, count.index + 2)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  tags = {
    Name = "internal-subnet-${count.index + 1}"
  }
}

# Route table for external subnets
resource "aws_route_table" "external" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "external-rt"
  }
}

# Route table for internal subnets
resource "aws_route_table" "internal" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "internal-rt"
  }
}

# Associate external subnets with external route table
resource "aws_route_table_association" "external" {
  count          = 2
  subnet_id      = aws_subnet.external[count.index].id
  route_table_id = aws_route_table.external.id
}

# Associate internal subnets with internal route table
resource "aws_route_table_association" "internal" {
  count          = 2
  subnet_id      = aws_subnet.internal[count.index].id
  route_table_id = aws_route_table.internal.id
}
