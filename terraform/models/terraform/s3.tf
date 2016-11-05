variable "account" {
  type        = "string"
  description = "The actual project account"
}

variable "shortname" {
  type        = "string"
  description = "The short name of the environment that is used to define it"
}

variable "region" {
  type        = "string"
  description = "AWS Region to use"
}

variable "uniquekey" {
  type        = "string"
  description = "A unique key to generate a new bucket"
}

resource "aws_s3_bucket" "terraform" {
  bucket = "terraform-${var.shortname}-${var.uniquekey}"
  acl    = "private"

  versioning {
    enabled = true
  }

  force_destroy = "false"
}

output "terraform_bucket" {
   value = "${aws_s3_bucket.terraform.bucket}"
}

