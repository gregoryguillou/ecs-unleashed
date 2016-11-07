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

variable "netprefix" {
  type        = "string"
  description = "Network Prefix for a /16 VPC range"
}

