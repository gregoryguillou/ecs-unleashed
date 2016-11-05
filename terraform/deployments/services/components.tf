variable "shortname" {
}
variable "account" {
}
variable "region" {
}
variable "uniquekey" {
}
variable "accountid" {
}

module "simple-api" {
  shortname = "${var.shortname}"
  account = "${var.account}"
  region = "${var.region}"
  source = "../../models/service-simple"
  name = "simple-api"
  image = "${var.accountid}.dkr.ecr.${var.region}.amazonaws.com/${var.shortname}-simple-api:0.0.10"
  port = "8080"
  cluster = "${data.terraform_remote_state.infra.autodiscovery_cluster}"
}

module "simple-gateway" {
  shortname = "${var.shortname}"
  account = "${var.account}"
  region = "${var.region}"
  source = "../../models/service-simple"
  name = "simple-gateway"
  image = "${var.accountid}.dkr.ecr.${var.region}.amazonaws.com/${var.shortname}-simple-gateway:0.0.6"
  port = "8080"
  cluster = "${data.terraform_remote_state.infra.autodiscovery_cluster}"
}
