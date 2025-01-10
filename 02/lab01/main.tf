## [0] Provider 설정
provider "aws" {
  # Configuration options
  region = "us-east-2"
}

## [1] VPC 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
# key_words : aws_vpc

resource "aws_vpc" "myVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC"
  }
}


## [2] Internet Gateway 생성 & VPC 연결
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "main"
  }
}



## [3] VPC에 Public Subnet 생성
resource "aws_subnet" "myPubSubnet" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "myPubSubnet"
  }
}


## [4] Public Routing Table 생성 & Public Subnet에 연결
resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubRT"
  }
}

resource "aws_route_table_association" "myPubRTassoc" {
  subnet_id      = aws_subnet.myPubSubnet.id
  route_table_id = aws_route_table.myPubRT.id
}

#######################


# SG 생성
resource "aws_security_group" "allow_myweb" {
  name        = "allow_http"
  description = "Allow HTTP TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "llow_http"
  }
}

# SG Rule 생성
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_myweb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_myweb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  security_group_id = aws_security_group.allow_myweb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



# EC2 생성 (user data)
# * ami: Amazon Linux 2023 AMI
resource "aws_instance" "myWEB" {
  ami                    = "ami-0ca2e925753ca2fb4"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.myPubSubnet.id
  vpc_security_group_ids = [aws_security_group.allow_myweb.id]

  user_data_replace_on_change = true
  user_data                   = <<-EOF
    #!/bin/bash
    yum -y install httpd
    echo 'MyWEB' > /var/www/html/index.html
    systemctl enable --now httpd
    EOF

  tags = {
    Name = "myWEB"
  }
}



