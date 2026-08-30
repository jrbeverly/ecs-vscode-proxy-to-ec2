#!/bin/bash
# Forward EC2:8080 to workspace localhost:18080 via SSM port forwarding.
#   app-proxy-up.sh INSTANCE_ID
set -euo pipefail

INSTANCE_ID="${1:?usage: app-proxy-up.sh INSTANCE_ID}"

aws ssm start-session \
  --target "$INSTANCE_ID" \
  --document-name "AWS-StartPortForwardingSession" \
  --parameters '{"portNumber":["8080"],"localPortNumber":["18080"]}'
