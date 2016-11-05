data "terraform_remote_state" "infra" {
  backend = "s3"

  config {
    bucket = "terraform-${var.shortname}-${var.uniquekey}"
    key = "tf-state/infrastructure.state"
    region = "${var.region}"
    profile = "${var.account}-${var.shortname}"
  }
}
