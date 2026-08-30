packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

locals {
  stamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

source "amazon-ebs" "al2023" {
  region        = "us-east-1"
  ami_name      = "ecs-vscode-proxy-to-ec2-bloodhound-${local.stamp}"
  instance_type = "t3.medium"
  ssh_username  = "ec2-user"

  # Some default subnets do not map public IPs on launch; without one the
  # SSH provisioner can never reach the builder.
  associate_public_ip_address = true

  tags = {
    Name = "ecs-vscode-proxy-to-ec2-bloodhound"
  }

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-kernel-*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }
}

build {
  sources = ["source.amazon-ebs.al2023"]

  provisioner "file" {
    source      = "docker-compose.bloodhound.yml"
    destination = "/tmp/docker-compose.bloodhound.yml"
  }

  provisioner "shell" {
    script          = "provision.sh"
    execute_command = "sudo -E bash '{{ .Path }}'"
  }
}
