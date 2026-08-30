#!/bin/bash
# Terminate the disposable EC2 by instance id, or by the launch tags when no
# id is given (one instance at a time).
#   destroy-ec2.sh [INSTANCE_ID...]
set -euo pipefail

if [ $# -ge 1 ]; then
  aws ec2 terminate-instances --instance-ids "$@"
else
  INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters \
    "Name=tag:WorkspaceId,Values=ws-1" \
    "Name=tag:EnvironmentType,Values=bloodhound" \
    "Name=tag:ManagedBy,Values=WorkspacePlatform" \
    "Name=instance-state-name,Values=pending,running,stopped" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text)
  aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
fi
