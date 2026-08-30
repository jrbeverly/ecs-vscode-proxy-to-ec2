#!/bin/bash
# Launch one disposable EC2 from the golden AMI into the private subnet and
# wait until SSM registers it (readiness signal).
#   launch-ec2.sh AMI_ID SUBNET_ID SECURITY_GROUP_ID
set -euo pipefail

AMI_ID="${1:?usage: launch-ec2.sh AMI_ID SUBNET_ID SECURITY_GROUP_ID}"
SUBNET_ID="${2:?usage: launch-ec2.sh AMI_ID SUBNET_ID SECURITY_GROUP_ID}"
SECURITY_GROUP_ID="${3:?usage: launch-ec2.sh AMI_ID SUBNET_ID SECURITY_GROUP_ID}"

# No key pair and no public IP; SSM is the only control path. The
# WorkspaceId tag is what the task role's ec2:RunInstances condition checks.
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t3.medium \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --iam-instance-profile Name=ecs-vscode-proxy-to-ec2-instance \
  --no-associate-public-ip-address \
  --tag-specifications \
  'ResourceType=instance,Tags=[{Key=WorkspaceId,Value=ws-1},{Key=EnvironmentType,Value=bloodhound},{Key=ManagedBy,Value=WorkspacePlatform},{Key=TTL,Value=4h}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "instance: $INSTANCE_ID"

until [ "$(aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
  --query 'InstanceInformationList[0].PingStatus' \
  --output text)" = "Online" ]; do
  echo "waiting for SSM registration..."
  sleep 10
done

echo "registered with SSM"
