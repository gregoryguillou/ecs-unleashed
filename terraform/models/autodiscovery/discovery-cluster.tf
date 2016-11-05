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

variable "ami" {
  type = "string"
  description = "The AMI to start from"
}

variable "vpc" {
  type = "string"
  description = "The Main VPC Identifier"
}

variable "subnets" {
  type = "list"
  description = "The list of subnet the cluster will use"
}

variable "security_group" {
  type = "string"
  description = "The default SSH security Group"
}

variable "keypair" {
  type = "string"
  description = "The Keypair to use"
}

variable "zone" {
  type = "string"
  description = "Route53 Private Hosted Zone for the VPC"
}

resource "aws_ecs_cluster" "autodiscovery" {
  name = "${var.shortname}-discovery"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "consul_sg" {
  name = "${var.shortname}-discovery-sg"
  description = "Security group for the EC2 instances of the Discovery ECS cluster"
  vpc_id = "${var.vpc}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "udp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 8400
    to_port = 8400
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 8600
    to_port = 8600
    protocol = "udp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

}

resource "aws_autoscaling_group" "autodiscovery" {
  name = "${var.shortname}-autodiscovery"
  launch_configuration = "${aws_launch_configuration.autodiscovery.name}"
  desired_capacity = 3
  min_size = 3
  max_size = 3
  vpc_zone_identifier = [
    "${var.subnets}"]


  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "Name"
    value = "${var.shortname}-discovery"
    propagate_at_launch = true
  }

  tag {
    key = "autodiscovery-key"
    value = "${var.uniquekey}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "autodiscovery" {
  name_prefix = "${var.shortname}-autodiscovery-"
  image_id = "${var.ami}"
  instance_type = "t2.small"
  key_name = "${var.keypair}"
  security_groups = [
    "${aws_security_group.consul_sg.id}",
    "${var.security_group}"]

  iam_instance_profile = "${aws_iam_instance_profile.autodiscovery_profile.name}"

  user_data = "${data.template_cloudinit_config.autodiscovery_cloudinit.rendered}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }

  ebs_block_device {
    device_name = "/dev/xvdcz"
    volume_size = 22
    volume_type = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_iam_instance_profile" "autodiscovery_profile" {
  name = "${var.shortname}-autodiscovery-profile"
  roles = [
    "${aws_iam_role.autodiscovery_role.id}"]

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = "sleep 30"
  }
}

resource "aws_iam_role" "autodiscovery_role" {
  name = "${var.shortname}-autodiscovery-role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "autodiscovery_permissions" {
  name = "${var.shortname}-autodiscovery-permissions"
  role = "${aws_iam_role.autodiscovery_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetAuthorizationToken",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "ec2:Describe*",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

data "template_file" "autodiscovery" {
  template = "${file("${path.module}/../templates/cluster.tpl")}"

  vars {
    clustername = "${aws_ecs_cluster.autodiscovery.name}"
  }
}

data "template_file" "consulserver" {
  template = "${file("${path.module}/../templates/consul.tpl")}"

  vars {
    clusterkey = "${var.uniquekey}"
    environment = "${var.shortname}"
    zone = "${var.zone}"
    config = "server"
    ui = "false"
  }
}

data "template_cloudinit_config" "autodiscovery_cloudinit" {
  gzip = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.autodiscovery.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.consulserver.rendered}"
  }
}

