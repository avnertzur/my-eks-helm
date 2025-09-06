# AWS VPC Terraform Configuration

This Terraform configuration creates a VPC with:
- VPC CIDR /14
- Two external subnets in two AZs with /16 CIDR
- Two internal subnets in two AZs with /16 CIDR
- One Internet Gateway for external subnets
- One NAT Gateway for internal subnets
