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

variable "name" {
  type = "string"
  description = "Container Short Name"
}

variable "image" {
  type = "string"
  description = "Container Image full name including Registry and Version"
}

variable "port" {
  type = "string"
  description = "Port inside the container"
}

variable "cluster" {
  type = "string"
  description = "The Identifier of the ECS Cluster to rely on"
}

resource "aws_ecs_task_definition" "service" {
  family = "${var.shortname}-${var.name}"

  network_mode = "bridge"

  container_definitions = <<EOF
[
  {
    "name": "${var.name}",
    "image": "${var.image}",
    "essential": true,
    "memory": 256,
    "memoryReservation": 128,
    "portMappings": [
      {
        "containerPort": ${var.port}
      }
    ],
    "logConfiguration": {
       "logDriver": "awslogs",
       "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.service_log.name}",
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "${var.name}"
        }
    },
    "environment": [
      { "name": "AWS_REGION", "value": "${var.region}" },
      { "name": "SERVICE_${var.port}_NAME", "value": "${var.name}" }
    ]
  }
]
EOF

}

resource "aws_cloudwatch_log_group" "service_log" {
  name = "${var.shortname}-service-${var.name}"
}

resource "aws_ecs_service" "service" {
  name = "${var.shortname}-service-${var.name}"
  cluster = "${var.cluster}"
  task_definition = "${aws_ecs_task_definition.service.arn}"
  desired_count = "2"
}
