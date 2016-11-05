variable "shortname" {}
variable "account" {}
variable "region" {}
variable "uniquekey" {}

module "state" {
  shortname = "${var.shortname}"
  account   = "${var.account}"
  region    = "${var.region}"
  uniquekey = "${var.uniquekey}"
  source  = "../../models/terraform"
}

output "terraform_bucket" {
  value = "${module.state.terraform_bucket}"
}
