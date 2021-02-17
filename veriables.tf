variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_path" {}
variable "aws_key_name" {}
variable "region" {
  default = "us-east-1"
}
variable "amis" {
    description = "AMIs by region"
    default = {
        us-east-1 = "ami-047a51fa27710816e" # ubuntu 14.04 LTS
    }
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "172.31.96.0/24"
}

variable "public_subnet_cidr" {
    description = "CIDR for the Public Subnet"
    default = "172.31.96.0/25"
}

variable "private_subnet_cidr" {
    description = "CIDR for the Private Subnet"
    default = "172.31.96.128/25"
}
