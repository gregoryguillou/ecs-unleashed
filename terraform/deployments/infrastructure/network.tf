variable "shortname" {}
variable "account" {}
variable "region" {}
variable "uniquekey" {}
variable "netprefix" {}

module "network" {
  shortname = "${var.shortname}"
  account   = "${var.account}"
  region    = "${var.region}"
  uniquekey = "${var.uniquekey}"
  netprefix = "${var.netprefix}"
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