output "vpc_id" {
  description = "Workspace VPC"
  value       = aws_vpc.ws.id
}

output "public_subnet_id" {
  description = "PUBLIC zone subnet (ALB)"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "WORKSPACE/EXECUTION zone subnet (ECS tasks + EC2)"
  value       = aws_subnet.private.id
}

output "alb_sg_id" {
  description = "PUBLIC zone security group (ALB)"
  value       = aws_security_group.alb.id
}

output "ecs_task_sg_id" {
  description = "WORKSPACE zone security group (ECS tasks)"
  value       = aws_security_group.ecs_task.id
}

output "ec2_sg_id" {
  description = "EXECUTION zone security group (disposable EC2)"
  value       = aws_security_group.ec2.id
}
