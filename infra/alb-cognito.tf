# Public ALB + Cognito: the HTTPS listener authenticates against the user
# pool, then forwards to the code-server target group.

variable "hosted_zone_name" {
  description = "Existing public Route53 zone, e.g. example.com"
  type        = string
}

variable "alb_hostname" {
  description = "Hostname for the workspace inside hosted_zone_name, e.g. workspace.example.com"
  type        = string
}

variable "workspace_password" {
  description = "Password for the seeded Cognito user"
  type        = string
  sensitive   = true
}

data "aws_route53_zone" "ws" {
  name = var.hosted_zone_name
}

resource "aws_acm_certificate" "ws" {
  domain_name       = var.alb_hostname
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ws.domain_validation_options : dvo.domain_name => dvo
  }

  zone_id = data.aws_route53_zone.ws.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "ws" {
  certificate_arn         = aws_acm_certificate.ws.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

resource "aws_route53_record" "ws" {
  zone_id = data.aws_route53_zone.ws.zone_id
  name    = var.alb_hostname
  type    = "A"

  alias {
    name                   = aws_lb.ws.dns_name
    zone_id                = aws_lb.ws.zone_id
    evaluate_target_health = false
  }
}

resource "aws_lb" "ws" {
  name               = "ecs-vscode-proxy-to-ec2"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ws.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.ws.certificate_arn

  default_action {
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.ws.arn
      user_pool_client_id = aws_cognito_user_pool_client.alb.id
      user_pool_domain    = aws_cognito_user_pool_domain.ws.domain
    }
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.workspace.arn
  }
}

resource "aws_cognito_user_pool" "ws" {
  name = "ecs-vscode-proxy-to-ec2"
}

# ALB authenticate-cognito needs the code grant with the openid scope and a
# client secret. The ALB handles the /oauth2/idpresponse callback.
resource "aws_cognito_user_pool_client" "alb" {
  name         = "ecs-vscode-proxy-to-ec2-alb"
  user_pool_id = aws_cognito_user_pool.ws.id

  generate_secret = true

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid"]

  callback_urls = ["https://${var.alb_hostname}/oauth2/idpresponse"]

  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "ws" {
  domain       = "ecs-vscode-proxy-to-ec2"
  user_pool_id = aws_cognito_user_pool.ws.id
}

resource "aws_cognito_user" "workspace" {
  user_pool_id = aws_cognito_user_pool.ws.id
  username     = "workspace"
  password     = var.workspace_password

  attributes = {
    email          = "workspace@example.com"
    email_verified = true
  }
}
