# provider 설정
provider "aws" {
  # Configuration options
  region = "us-east-2"
}

##[1] - SG (security group) 생성 - 8080
resource "aws_security_group" "allow_8080" {
  name        = "allow_8080"
  description = "Allow 8080 inbound traffic and all outbound traffic"
  #vpc_id      = aws_vpc.main.id

  tags = {
    Name = "my_allow_8080"
  }
}

# SG ingress rule
resource "aws_vpc_security_group_ingress_rule" "allow_http_8080" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

# SG egress rule 
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

## [2] - EC2 생성
resource "aws_instance" "example" {
  ami           = "ami-036841078a4b68e14"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.allow_8080.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello World" > index.html
    nohup busybox httpd -f -p 8080 &
    EOF

  user_data_replace_on_change = true

  tags = {
  
    Name = "myweb"
  }
}
