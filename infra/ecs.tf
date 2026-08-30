# ECS workspace: Fargate task running the workspace image (code-server on
# 8080) in the private subnet, registered with the ALB target group.

resource "aws_ecr_repository" "workspace" {
  name         = "ecs-vscode-proxy-to-ec2-workspace"
  force_delete = true
}

resource "aws_ecs_cluster" "ws" {
  name = "ecs-vscode-proxy-to-ec2"
}

resource "aws_cloudwatch_log_group" "workspace" {
  name = "/ecs/ecs-vscode-proxy-to-ec2"
}

resource "aws_lb_target_group" "workspace" {
  name        = "ecs-vscode-proxy-to-ec2-ws"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.ws.id

  health_check {
    path    = "/healthz"
    matcher = "200"
  }
}

resource "aws_ecs_task_definition" "workspace" {
  family                   = "ecs-vscode-proxy-to-ec2-workspace"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name  = "code-server"
      image = "${aws_ecr_repository.workspace.repository_url}:latest"

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.workspace.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "code-server"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "workspace" {
  name            = "ecs-vscode-proxy-to-ec2-workspace"
  cluster         = aws_ecs_cluster.ws.id
  task_definition = aws_ecs_task_definition.workspace.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private.id]
    security_groups  = [aws_security_group.ecs_task.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.workspace.arn
    container_name   = "code-server"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.https]
}
