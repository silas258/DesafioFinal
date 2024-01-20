variable "region" {
  default = "us-east-1"
}

variable "profile" {
  default = "default"
}

variable "name_security_group" {
  default = "allow"
}

variable "vpc_id_security_group" {
  default = "vpc-0baf6f6d8f014992e"
}

variable "ami_aws_instance" {
  default = "ami-053b0d53c279acc90"
}

variable "type_aws_instance" {
  default = "t2.micro"
}

variable "subnet_id_aws_instance" {
  default = "subnet-0d1169d21959c2ca3"
}

variable "key_aws_instance" {
  default = "curso-terraform"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

