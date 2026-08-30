#!/bin/bash
# Start BloodHound on the EC2 over SSM and wait until localhost:8080 answers.
#   bloodhound-up.sh INSTANCE_ID
set -euo pipefail

INSTANCE_ID="${1:?usage: bloodhound-up.sh INSTANCE_ID}"

UP_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["docker compose -f /opt/bloodhound/docker-compose.yml up -d"]' \
  --query 'Command.CommandId' \
  --output text)

until [ "$(aws ssm get-command-invocation \
    --instance-id "$INSTANCE_ID" \
    --command-id "$UP_ID" \
    --query 'Status' \
    --output text 2>/dev/null)" = "Success" ]; do
  echo "waiting for compose up..."
  sleep 5
done

echo "compose stack started"

while true; do
  CURL_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["curl -sf http://localhost:8080"]' \
    --query 'Command.CommandId' \
    --output text)

  STATUS=""
  while [ "$STATUS" = "" ] || [ "$STATUS" = "Pending" ] || [ "$STATUS" = "InProgress" ]; do
    sleep 3
    STATUS=$(aws ssm get-command-invocation \
      --instance-id "$INSTANCE_ID" \
      --command-id "$CURL_ID" \
      --query 'Status' \
      --output text 2>/dev/null || true)
  done

  [ "$STATUS" = "Success" ] && break
  echo "waiting for BloodHound..."
  sleep 10
done

echo "BloodHound is up"
