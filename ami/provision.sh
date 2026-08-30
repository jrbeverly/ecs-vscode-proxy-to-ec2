#!/bin/bash
set -eu

dnf install -y docker

# AL2023 has no docker-compose-plugin rpm; use the upstream binary (AWS ECS docs pattern).
mkdir -p /usr/libexec/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.40.3/docker-compose-linux-x86_64 \
  -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

rpm -q amazon-ssm-agent
systemctl enable amazon-ssm-agent

mkdir -p /opt/bloodhound
cp /tmp/docker-compose.bloodhound.yml /opt/bloodhound/docker-compose.yml

docker compose -f /opt/bloodhound/docker-compose.yml pull
