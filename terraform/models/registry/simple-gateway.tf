variable "account" {
  type = "string"
  description = "The actual project account"
}

variable "shortname" {
  type = "string"
  description = "The short name of the environment that is used to define it"
}

variable "region" {
  type = "string"
  description = "AWS Region to use"
}

variable "uniquekey" {
  type = "string"
  description = "A unique key to generate a new bucket"
}

resource "aws_ecr_repository" "simple-gateway" {
  name = "${var.shortname}-simple-gateway"
}

resource "aws_ecr_repository_policy" "simple-gateway_policy" {
  repository = "${aws_ecr_repository.simple-gateway.name}"

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

