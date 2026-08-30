# Three zones on two subnets: PUBLIC = public subnet + ALB SG,
# WORKSPACE = private subnet + ECS task SG, EXECUTION = private subnet +
# EC2 SG with no inbound. The ECS/EC2 boundary is enforced by security
# groups, not subnets.

resource "aws_vpc" "ws" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "ecs-vscode-proxy-to-ec2"
  }
}

resource "aws_internet_gateway" "ws" {
  vpc_id = aws_vpc.ws.id

  tags = {
    Name = "ecs-vscode-proxy-to-ec2"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.ws.id
  cidr_block        = "10.10.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "ecs-vscode-proxy-to-ec2-public"
  }
}

# ALBs need subnets in two AZs; this second public subnet exists only for that.
resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.ws.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "ecs-vscode-proxy-to-ec2-public-b"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.ws.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "ecs-vscode-proxy-to-ec2-private"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "ws" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.ws]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ws.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ws.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ws.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ws.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
