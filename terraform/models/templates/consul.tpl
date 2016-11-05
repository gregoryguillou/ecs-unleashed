#!/bin/bash

mkdir -p /var/consul/conf

#
# Set variables
#
IPADDR=$(curl -q http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null)
HOST_NAME=$(curl -q http://169.254.169.254/latest/meta-data/hostname 2>/dev/null)
INSTANCE=$(curl -q http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)
DNS="$(echo $IPADDR | cut -d'.' -f 1-2).0.2"
export AWS_DEFAULT_REGION=$(curl -q http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null|sed 's/.$//')
IPADRESSES=""
CLUSTERNAMES=""

for i in $(aws ec2 describe-tags --filters "Name=tag:autodiscovery-key,Values=${clusterkey}" --query "Tags[*].ResourceId" --output=text); do
    ipaddress=$(aws ec2 describe-instances --instance-id $i --query Reservations[0].Instances[?State.Name==\`running\`].PrivateIpAddress --output=text)
    if [ "$i" != "$INSTANCE" ]; then
        ipaddress=$(aws ec2 describe-instances --instance-id $i --query Reservations[0].Instances[?State.Name==\`running\`].PrivateIpAddress --output=text)
        IPADRESSES="$IPADRESSES $ipaddress"
    fi
    clustername=$(aws ec2 describe-instances --instance-id $i --query Reservations[0].Instances[?State.Name==\`running\`].PrivateDnsName --output=text)
    CLUSTERNAMES="$CLUSTERNAMES $clustername"
done

serverconf() {
    cat >/var/consul/conf/consul.conf <<EOF
{
  "datacenter": "$AWS_DEFAULT_REGION",
  "data_dir": "/consul/data",
  "client_addr": "0.0.0.0",
  "advertise_addr": "$IPADDR",
  "bootstrap_expect": 3,
  "log_level": "INFO",
  "node_name": "$HOST_NAME",
  "server": true,
  "addresses": {
    "https": "0.0.0.0"
  },
  "retry_join": [
EOF

    words=$(echo "$IPADRESSES" | wc -w)
    count=1
    for i in $IPADRESSES; do
        if [ "$count" -eq "$words" ]; then
            echo "    \"$i\"" >> /var/consul/conf/consul.conf
        else
            echo "    \"$i\"," >> /var/consul/conf/consul.conf
        fi
        count=$(($count+1))
    done

    cat >>/var/consul/conf/consul.conf <<EOF
  ],
  "recursors": [ "$DNS" ]
}
EOF
}

agentconf() {
    cat >/var/consul/conf/consul.conf <<EOF
{
  "datacenter": "$AWS_DEFAULT_REGION",
  "data_dir": "/consul/data",
  "client_addr": "0.0.0.0",
  "advertise_addr": "$IPADDR",
  "log_level": "INFO",
  "node_name": "$HOST_NAME",
  "server": false,
  "ui": ${ui},
  "addresses": {
    "https": "0.0.0.0"
  },
  "start_join": [
     "consul1.${environment}.local",
     "consul2.${environment}.local",
     "consul3.${environment}.local"
  ],
  "recursors": [ "$DNS" ]
}
EOF
}

namingconf() {
    cat >/tmp/names.json <<EOF
{
  "Comment": "Update Consul Server Addresses",
  "Changes": [
EOF

    words=$(echo "$CLUSTERNAMES" | wc -w)
    count=1

    for i in $CLUSTERNAMES; do

        cat >>/tmp/names.json <<EOF
   {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "consul$count.${environment}.local.",
      "TTL": 30,
      "ResourceRecords": [
        {
          "Value": "$i"
        }
      ],
      "Type": "CNAME"
    }
  }
EOF
        if [ "$count" -ne "$words" ]; then
            echo "  ," >> /tmp/names.json
        fi
        count=$(($count+1))
    done

    cat >>/tmp/names.json <<EOF
  ]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id ${zone} --change-batch file:///tmp/names.json

}

if [ "${config}" == "server" ]; then
    serverconf
    namingconf
else
    agentconf
fi

