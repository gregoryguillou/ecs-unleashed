variable "keypair" {
  type = "string"
  description = "The Keypair to use"
}

variable "ami" {
  type = "string"
  description = "The AMI to start from"
}

resource "aws_instance" "bastion" {
  ami = "${var.ami}"
  key_name = "${var.keypair}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}"]
  subnet_id = "${aws_subnet.public-subnet-a.id}"
  instance_type = "t2.micro"

  tags {
    Name = "${var.shortname}-bastion"
    env = "${var.shortname}"
    uniquekey = "${var.uniquekey}"
  }
}

output "bastion_access" {
  value = "ec2-user@${aws_instance.bastion.public_ip}"
}
