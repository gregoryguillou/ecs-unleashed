variable "account" {
  type        = "string"
  description = "The actual project account"
}

variable "shortname" {
  type        = "string"
  description = "The short name of the environment that is used to define it"
}

variable "region" {
  type        = "string"
  description = "AWS Region to use"
}

variable "uniquekey" {
  type        = "string"
  description = "A unique key to generate a new bucket"
}

variable "netprefix" {
  type        = "string"
  description = "Network Prefix for a /16 VPC range"
}

resource "aws_vpc" "main" {
    cidr_block = "${var.netprefix}.0.0/16"

    tags {
        name = "${var.shortname}"
        env = "${var.shortname}"
        uniquekey = "${var.uniquekey}"
    }
}

output "vpc" {
   value = "${aws_vpc.main.id}"
}

resource "aws_subnet" "public-subnet-a" {
  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${var.region}a"
  cidr_block        = "${var.netprefix}.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.shortname}-public-subnet-a"
    env       = "${var.shortname}"
    uniquekey = "${var.uniquekey}"
  }
}

output "public-subnets" {
  value = [ "${aws_subnet.public-subnet-a.id}" ]
}

resource "aws_subnet" "private-subnet-a" {
  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${var.region}a"
  cidr_block        = "${var.netprefix}.8.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name      = "${var.shortname}-private-subnet-a"
    env       = "${var.shortname}"
    uniquekey = "${var.uniquekey}"
  }
}

resource "aws_subnet" "private-subnet-b" {
  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${var.region}b"
  cidr_block        = "${var.netprefix}.9.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name      = "${var.shortname}-private-subnet-b"
    env       = "${var.shortname}"
    uniquekey = "${var.uniquekey}"
  }
}

resource "aws_subnet" "private-subnet-c" {
  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${var.region}c"
  cidr_block        = "${var.netprefix}.10.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name      = "${var.shortname}-private-subnet-c"
    env       = "${var.shortname}"
    uniquekey = "${var.uniquekey}"
  }
}

output "private-subnets" {
  value = [ "${aws_subnet.private-subnet-a.id}", "${aws_subnet.private-subnet-b.id}", "${aws_subnet.private-subnet-c.id}" ]
}

/*##########################################################
# Internet Gateway
# ..... Create and Route
##########################################################*/

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name      = "${var.shortname}-igw"
    env       = "${var.shortname}"
    uniquekey = "${var.uniquekey}"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name      = "${var.shortname}-public-rt"
    env       = "${var.shortname}"
    uniquekey = "${var.uniquekey}"
  }

}

resource "aws_route_table_association" "public-subnet-a-assoc" {
  subnet_id      = "${aws_subnet.public-subnet-a.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}

/*##########################################################
# NAT Gateway
# ..... Create and Route
##########################################################*/

resource "aws_eip" "natgw-a" {
  vpc = true
}

resource "aws_nat_gateway" "natgw-a" {
  allocation_id = "${aws_eip.natgw-a.id}"
  subnet_id     = "${aws_subnet.public-subnet-a.id}"
  depends_on    = ["aws_internet_gateway.igw"]
}

resource "aws_route_table" "private-rt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.natgw-a.id}"
  }

  tags = {
    Name      = "${var.shortname}-private-rt"
    env       = "${var.shortname}"
    uniquekey = "${var.uniquekey}"
  }
}

resource "aws_route_table_association" "private-subnet-a-assoc" {
  subnet_id      = "${aws_subnet.private-subnet-a.id}"
  route_table_id = "${aws_route_table.private-rt.id}"
}

resource "aws_route_table_association" "private-subnet-b-assoc" {
  subnet_id      = "${aws_subnet.private-subnet-b.id}"
  route_table_id = "${aws_route_table.private-rt.id}"
}

resource "aws_route_table_association" "private-subnet-c-assoc" {
  subnet_id      = "${aws_subnet.private-subnet-c.id}"
  route_table_id = "${aws_route_table.private-rt.id}"
}

/*##########################################################
# Simple (Unsecured) Security Group
# .....
##########################################################*/

resource "aws_security_group" "ssh" {
  name        = "${var.shortname}-ssh"
  description = "Allow incoming SSH connections from anywhere"
  vpc_id      = "${aws_vpc.main.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    env       = "${var.shortname}"
    uniquekey = "${var.uniquekey}"
  }
}

output "ssh_security_group" {
  value = "${aws_security_group.ssh.id}"
}
