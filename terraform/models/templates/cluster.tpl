#!/bin/bash

cat >/etc/ecs/ecs.config <<FINISH
ECS_CLUSTER=${clustername}
ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
FINISH

yum install -y aws-cli
yum install -y python27-pip
yum update -y ecs-init
yum install -y bind-utils
yum -y update

python -m pip install --upgrade pip
python -m pip install --upgrade boto3
python -m pip install --upgrade requests

curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O

cat >>/tmp/awslog.conf <<EOF
[general]
state_file = /var/awslogs/state/agent-state

[/var/log/messages]
file = /var/log/messages
log_group_name = /var/log/messages
log_stream_name = {instance_id}
datetime_format = %b %d %H:%M:%S
EOF

python awslogs-agent-setup.py -n -r eu-west-1 -c /tmp/awslog.conf
