provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.region}"
}

resource "aws_vpc" "centrix_vpc" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags = {
        Name = "centrix-aws-vpc"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.centrix_vpc.id}"
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}

/*
  NAT Instance
*/

resource "aws_security_group" "nat" {
    name = "vpc_nat"
    description = "Allow traffic to pass from the private subnet to the internet"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.centrix_vpc.id}"

    tags = {
        Name = "NATSG"
    }
}

resource "aws_instance" "Bastion_nat" {
    ami = "ami-047a51fa27710816e"
    availability_zone = "us-east-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.nat.id}"]
    subnet_id = "${aws_subnet.us-east-1a-public.id}"
    associate_public_ip_address = true
    source_dest_check = false
    iam_instance_profile = "centrix_app_role"
    tags = {
        Name = "VPC NAT"
    }
}

/*
  Public Subnet
*/
resource "aws_subnet" "us-east-1a-public" {
    vpc_id = "${aws_vpc.centrix_vpc.id}"
    cidr_block = "${var.public_subnet_cidr}"
    availability_zone = "us-east-1a"
    tags = {
        Name = "Public Subnet"
    }
}



resource "aws_route_table" "us-east-1a-public" {
    vpc_id = "${aws_vpc.centrix_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }

    tags = {
        Name = "Public Subnet"
    }
}


resource "aws_route_table_association" "us-east-1a-public" {
    subnet_id = "${aws_subnet.us-east-1a-public.id}"
    route_table_id = "${aws_route_table.us-east-1a-public.id}"
}

/*
  Private Subnet
*/

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.us-east-1a-public.id
  tags = {
    Name = "gw NAT"
  }
}

resource "aws_subnet" "us-east-1a-private" {
    vpc_id = "${aws_vpc.centrix_vpc.id}"

    cidr_block = "${var.private_subnet_cidr}"
    availability_zone = "us-east-1a"

    tags = {
        Name = "Private Subnet"
    }
}

resource "aws_route_table" "us-east-1a-private" {
    vpc_id = "${aws_vpc.centrix_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.gw.id}"
    }

    tags = {
        Name = "Private Subnet"
    }
}


resource "aws_route_table_association" "us-east-1a-private" {
    subnet_id = "${aws_subnet.us-east-1a-private.id}"
    route_table_id = "${aws_route_table.us-east-1a-private.id}"
}
