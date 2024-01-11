terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.5.6"
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

resource "aws_security_group" "allow_ssh" {
  name        = var.name_security_group
  description = "Allow ssh inbound traffic"
  vpc_id      = var.vpc_id_security_group
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_SSH"
  }
}

resource "aws_instance" "maquina" {
  ami                          = var.ami_aws_instance
  instance_type                = var.type_aws_instance
  vpc_security_group_ids       = [aws_security_group.allow_ssh.id]
  key_name                     = var.key_aws_instance
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update && sudo apt install curl ansible unzip -y
              cd /tmp
              wget https://esseeutenhocertezaqueninguemcriou.s3.amazonaws.com/ansible.zip
              unzip ansible.zip
              sudo ansible-playbook wordpress.yml
              EOF
  monitoring                   = true
  subnet_id                    = var.subnet_id_aws_instance
  associate_public_ip_address  = true
  tags = {
    Name = "Minha_primeira_maquina"
  }
}

#module "ec2_instance" {
#  source  = "terraform-aws-modules/ec2-instance/aws"

#  name = "desafioTerraform"
#  instance_count         = 2
#  instance_type          = var.type_aws_instance
#  key_name               = var.key_aws_instance
#  monitoring             = false
#  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
#  subnet_id              = var.subnet_id_aws_instance
#  associate_public_ip_address = true
#  tags = {
#    Name = "Minha_primeira_maquina"
#  }
#}
