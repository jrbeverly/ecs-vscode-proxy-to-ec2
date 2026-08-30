# Task execution role (image pull, logs) and task role. The task role is
# the narrow SSM/EC2/PassRole set — deliberately not ec2:*, ssm:*, or
# iam:*.

resource "aws_iam_role" "execution" {
  name = "ecs-vscode-proxy-to-ec2-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "execution" {
  name = "ecs-vscode-proxy-to-ec2-execution"
  role = aws_iam_role.execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ]
        Resource = aws_ecr_repository.workspace.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "${aws_cloudwatch_log_group.workspace.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role" "task" {
  name = "ecs-vscode-proxy-to-ec2-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "task" {
  name = "ecs-vscode-proxy-to-ec2-task"
  role = aws_iam_role.task.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:StartSession"]
        Resource = ["arn:aws:ec2:us-east-1:*:instance/*"]
        Condition = {
          StringEquals = {
            "ssm:resourceTag/WorkspaceId" = "ws-1"
          }
          BoolIfExists = {
            "ssm:SessionDocumentAccessCheck" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = ["ssm:StartSession"]
        Resource = [
          "arn:aws:ssm:us-east-1:*:document/SSM-SessionManagerRunShell",
          "arn:aws:ssm:us-east-1:*:document/AWS-StartPortForwardingSession",
          "arn:aws:ssm:us-east-1:*:document/AWS-StartSSHSession",
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:SendCommand"]
        Resource = ["arn:aws:ec2:us-east-1:*:instance/*"]
        Condition = {
          StringEquals = {
            "ssm:resourceTag/WorkspaceId" = "ws-1"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:SendCommand"]
        Resource = ["arn:aws:ssm:us-east-1:*:document/AWS-RunShellScript"]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetCommandInvocation"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:DescribeInstanceInformation"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:TerminateSession"]
        Resource = ["arn:aws:ssm:us-east-1:*:session/*"]
      },
      {
        # aws:RequestTag only exists on the resources being tagged, so the
        # condition goes on instance/* and the other resources RunInstances
        # touches are allowed separately.
        Effect   = "Allow"
        Action   = ["ec2:RunInstances"]
        Resource = ["arn:aws:ec2:us-east-1:*:instance/*"]
        Condition = {
          StringEquals = {
            "aws:RequestTag/WorkspaceId" = "ws-1"
          }
        }
      },
      {
        Effect = "Allow"
        Action = ["ec2:RunInstances"]
        Resource = [
          "arn:aws:ec2:us-east-1::image/*",
          "arn:aws:ec2:us-east-1:*:subnet/*",
          "arn:aws:ec2:us-east-1:*:security-group/*",
          "arn:aws:ec2:us-east-1:*:network-interface/*",
          "arn:aws:ec2:us-east-1:*:volume/*",
        ]
      },
      {
        # Tagging at launch (--tag-specifications) is a separate CreateTags
        # authorization on the new instance.
        Effect   = "Allow"
        Action   = ["ec2:CreateTags"]
        Resource = ["arn:aws:ec2:us-east-1:*:instance/*"]
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "RunInstances"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:TerminateInstances"]
        Resource = ["arn:aws:ec2:us-east-1:*:instance/*"]
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/WorkspaceId" = "ws-1"
          }
        }
      },
      {
        # DescribeInstances has no resource-level or tag-based scoping.
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = [aws_iam_role.instance.arn]
      }
    ]
  })
}

# EC2 instance role, the only PassRole target. Its policies arrive with
# the environment lifecycle step.
resource "aws_iam_role" "instance" {
  name = "ecs-vscode-proxy-to-ec2-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
