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

