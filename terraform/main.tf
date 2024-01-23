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

# Criação da VPC
resource "aws_vpc" "vpc_prd" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Minha_VPC"
  }
}

# Criação das Subnet Públicas
resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.vpc_prd.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Subnet_publica_a"
  }
}


resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.vpc_prd.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Subnet_publica_b"
  }
}

#Criação das Subnets privadas
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.vpc_prd.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Subnet_privada_a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.vpc_prd.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Subnet_privada_b"
  }
}

# Criação do Internet Gateway
resource "aws_internet_gateway" "igw_desafiofinal" {
  vpc_id = aws_vpc.vpc_prd.id

  tags = {
    Name = "igw_desafiofinal"
  }
}

# Crição de IP Elastico
resource "aws_eip" "ip_elastico_nat" {

  depends_on = [ aws_internet_gateway.igw_desafiofinal ]
}

# Criação de Nat Gateway
resource "aws_nat_gateway" "nat_gateway_desafio_final" {
  allocation_id = aws_eip.ip_elastico_nat.id
  subnet_id = aws_subnet.public_subnet_a.id
  
  depends_on = [ aws_internet_gateway.igw_desafiofinal ]
}

# Criação da Tabela de rotas publica
resource "aws_route_table" "rtb_desafiofinal_publica" {
  vpc_id = aws_vpc.vpc_prd.id

  route {
    cidr_block = "0.0.0.0/0"                              #destino  = quem tem acesso
    gateway_id = aws_internet_gateway.igw_desafiofinal.id #alvo     = porta para o acesso
  }
}

# Criação da Tabela de rotas privada
resource "aws_route_table" "rtb_desafiofinal_privada" {
  vpc_id = aws_vpc.vpc_prd.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_desafio_final.id
  }
}

# Associação da Subnet Pública A com a Tabela de Roteamento publica
resource "aws_route_table_association" "rtb_pub_association_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.rtb_desafiofinal_publica.id
}

# Associação da Subnet Pública B com a Tabela de Roteamento publica
resource "aws_route_table_association" "rtb_pub_association_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.rtb_desafiofinal_publica.id
}

# Associação da Subnet Privada A com a Tabela de Roteamento priv
resource "aws_route_table_association" "rtb_priv_association_a" {
  subnet_id = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.rtb_desafiofinal_privada.id
}

# Associação da Subnet Privada B com a Tabela de Roteamento priv
resource "aws_route_table_association" "rtb_priv_association_b" {
  subnet_id = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.rtb_desafiofinal_privada.id
}

#Criação grupo de segurança
resource "aws_security_group" "allow_ssh" {
  name        = var.name_security_group
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.vpc_prd.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
  count                       = 2
  ami                         = var.ami_aws_instance
  instance_type               = var.type_aws_instance
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  key_name                    = var.key_aws_instance
  
  /*
  user_data                   = <<-EOF
     #!/bin/bash
     sudo apt update && sudo apt install curl ansible unzip -y
     cd /tmp
     wget https://silas-teste1.s3.amazonaws.com/ansible.zip
     unzip ansible.zip
     cd /tmp/ansible # Navega até o diretório do playbook
     #export WORDPRESS_DB_HOST=$(terraform output rds_endpoint)
     sudo chmod -R 755 /var/www/html/wordpress
     sudo ansible-playbook wordpress.yml
  EOF
  */

  monitoring                  = true
  subnet_id                   = aws_subnet.public_subnet_a.id
  associate_public_ip_address = true
  tags = {
    Name = "Maquinas Wordpress"
  }
}

resource "aws_db_instance" "my_db_instance" {
  identifier          = "db-wordpress"
  allocated_storage   = 10
  engine              = "mysql"
  engine_version      = "5.7"
  instance_class      = "db.t2.micro"
  username            = "admin"
  password            = "password"
  publicly_accessible = false
  multi_az            = false
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name

  tags = {
    Name = "Meu_Banco_de_Dados"
  }
}

# Saída para o endpoint DNS do RDS
#output "rds_endpoint" {
 # value = aws_db_instance.my_db_instance.endpoint
#}

#serve para utilizar multi-a-z
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "mydbsubnetgroup"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]  #tirei para testar depois preciso acrestar aws_subnet.private_subnet_b.id
}

# Tirei esse bloco de código
# Criação da Rota Default para Acesso à Internet
#resource "aws_route" "rtb_default_desafiofinal" {
#  route_table_id         = aws_route_table.rtb_desafiofinal.id
#  destination_cidr_block = "0.0.0.0/0"
#  gateway_id             = aws_internet_gateway.igw_desafiofinal.id
#}
