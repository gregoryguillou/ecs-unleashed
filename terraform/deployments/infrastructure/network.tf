variable "shortname" {}
variable "account" {}
variable "region" {}
variable "uniquekey" {}
variable "netprefix" {}
variable "keypair" {
}
variable "ami" {
}

module "network" {
  shortname = "${var.shortname}"
  account   = "${var.account}"
  region    = "${var.region}"
  uniquekey = "${var.uniquekey}"
  netprefix = "${var.netprefix}"
  keypair = "${var.keypair}"
  ami = "${var.ami}"
  source  = "../../models/vpc"
}

output "vpc" {
  value = "${module.network.vpc}"
}

output "public_subnets" {
  value = "${module.network.public-subnets}"
}

output "private_subnets" {
  value = "${module.network.private-subnets}"
}

output "ssh_security_group" {
  value = "${module.network.ssh_security_group}"
}

output "bastion_access" {
  value = "${module.network.bastion_access}"
}
