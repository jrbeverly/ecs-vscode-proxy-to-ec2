resource "aws_security_group" "alb" {
  name        = "ecs-vscode-proxy-to-ec2-alb"
  description = "PUBLIC zone: 443 from the internet"
  vpc_id      = aws_vpc.ws.id

  ingress {
    description = "HTTPS from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_task" {
  name        = "ecs-vscode-proxy-to-ec2-task"
  description = "WORKSPACE zone: 8080 from the ALB SG only"
  vpc_id      = aws_vpc.ws.id

  ingress {
    description     = "code-server from the ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# No ingress at all: the EC2 is reachable only through the SSM agent's
# outbound connection, never by an inbound path.
resource "aws_security_group" "ec2" {
  name        = "ecs-vscode-proxy-to-ec2-execution"
  description = "EXECUTION zone: egress only, no inbound"
  vpc_id      = aws_vpc.ws.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
