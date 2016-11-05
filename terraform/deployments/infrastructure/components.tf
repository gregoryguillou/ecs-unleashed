variable "shortname" {}
variable "account" {}
variable "region" {}
variable "uniquekey" {}
variable "netprefix" {}
variable "keypair" {
}
variable "ami-ec2" {
}
variable "ami-ecs" {
}

module "network" {
  shortname = "${var.shortname}"
  account   = "${var.account}"
  region    = "${var.region}"
  uniquekey = "${var.uniquekey}"
  netprefix = "${var.netprefix}"
  keypair = "${var.keypair}"
  ami = "${var.ami-ec2}"
  source  = "../../models/vpc"
}

module "autodiscovery" {
  shortname = "${var.shortname}"
  account = "${var.account}"
  region = "${var.region}"
  uniquekey = "${var.uniquekey}"
  keypair = "${var.keypair}"
  vpc = "${module.network.vpc}"
  keypair = "${var.keypair}"
  zone = "${module.network.phz_zone}"
  security_group = "${module.network.ssh_security_group}"
  subnets = "${module.network.private-subnets}"
  ami = "${var.ami-ecs}"
  source = "../../models/autodiscovery"
}

module "registry" {
  shortname = "${var.shortname}"
  account = "${var.account}"
  region = "${var.region}"
  uniquekey = "${var.uniquekey}"
  source = "../../models/registry"
}

output "bastion_access" {
  value = "${module.network.bastion_access}"
}

output "autodiscovery_cluster" {
  value = "${module.autodiscovery.cluster}"
}
