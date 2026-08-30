#!/bin/bash
# Interactive Session Manager shell on the launched instance.
#   ssm-shell.sh INSTANCE_ID
set -euo pipefail

INSTANCE_ID="${1:?usage: ssm-shell.sh INSTANCE_ID}"
aws ssm start-session --target "$INSTANCE_ID"
