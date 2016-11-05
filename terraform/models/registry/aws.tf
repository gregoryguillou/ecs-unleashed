provider "aws" {
  profile = "${var.account}-${var.shortname}"
  region = "${var.region}"
}
