resource "aws_vpc" "main" {
    cidr_block = "${var.netprefix}.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

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

resource "aws_route53_zone" "phz" {
  name = "${var.shortname}.local"
  comment = "Private Hosted Zone for ${aws_vpc.main.id}"

  vpc_id = "${aws_vpc.main.id}"
  force_destroy = true

  tags = {
    env = "${var.shortname}"
    uniquekey = "${var.uniquekey}"
  }
}

output "phz_zone" {
  value = "${aws_route53_zone.phz.zone_id}"
}
