resource "aws_ecs_task_definition" "consul" {
  family = "${var.shortname}-consul"

  network_mode = "host"

  container_definitions = <<EOF
[
  {
    "name": "consul",
    "image": "consul:0.7.0",
    "essential": true,
    "memory": 256,
    "memoryReservation": 128,
    "command": [ "consul", "agent", "-config-file=/consul/config/consul.conf" ],
    "portMappings": [
      {
        "containerPort": 8300,
        "hostPort": 8300,
        "protocol": "tcp"
      },
      {
        "containerPort": 8301,
        "hostPort": 8301,
        "protocol": "tcp"
      },
      {
        "containerPort": 8302,
        "hostPort": 8302,
        "protocol": "tcp"
      },
      {
        "containerPort": 8301,
        "hostPort": 8301,
        "protocol": "udp"
      },
      {
        "containerPort": 8302,
        "hostPort": 8302,
        "protocol": "udp"
      },
      {
        "containerPort": 8400,
        "hostPort": 8400,
        "protocol": "tcp"
      },
      {
        "containerPort": 8500,
        "hostPort": 8500,
        "protocol": "tcp"
      },
      {
        "containerPort": 8600,
        "hostPort": 8600,
        "protocol": "udp"
      }
    ],
    "mountPoints": [
      {
        "sourceVolume": "consulconfig",
        "containerPath": "/consul/config"
      }
    ],
    "logConfiguration": {
       "logDriver": "awslogs",
       "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.consul_log.name}",
          "awslogs-region": "eu-west-1",
          "awslogs-stream-prefix": "consul"
        }
    },
    "environment": [
      { "name": "AWS_REGION", "value": "eu-west-1" }
    ]
  }
]
EOF

  volume {
    name = "consulconfig"
    host_path = "/var/consul/conf"
  }

}

resource "aws_cloudwatch_log_group" "consul_log" {
  name = "docker-${var.shortname}-consul"
}

resource "aws_ecs_service" "consul_server" {
  name = "${var.shortname}-consul-server"
  cluster = "${aws_ecs_cluster.autodiscovery.id}"
  task_definition = "${aws_ecs_task_definition.consul.arn}"
  desired_count = "3"
}

resource "aws_ecs_task_definition" "registrator" {
  family = "${var.shortname}-registrator"
  network_mode = "host"
  container_definitions = <<EOF
[
   {
    "name": "registrator",
    "essential": true,
    "memory": 128,
    "memoryReservation": 64,
    "image": "gliderlabs/registrator:latest",
    "command": [ "consul://localhost:8500" ],
    "mountPoints": [
      {
        "containerPath": "/tmp/docker.sock",
        "sourceVolume": "docker_socket"
      }
    ],
    "logConfiguration": {
       "logDriver": "awslogs",
       "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.registrator_log.name}",
          "awslogs-region": "eu-west-1",
          "awslogs-stream-prefix": "registrator"
        }
    },
    "portMappings": [
      {
        "containerPort": 6666,
        "hostPort": 6666,
        "protocol": "tcp"
      }
    ]
  }
]
EOF

  volume {
    name = "docker_socket"
    host_path = "/var/run/docker.sock"
  }
}

resource "aws_cloudwatch_log_group" "registrator_log" {
  name = "docker-${var.shortname}-registrator"
}

resource "aws_ecs_service" "registrator_server" {
  name = "${var.shortname}-registrator-server"
  cluster = "${aws_ecs_cluster.autodiscovery.id}"
  task_definition = "${aws_ecs_task_definition.registrator.arn}"
  desired_count = "3"
}
