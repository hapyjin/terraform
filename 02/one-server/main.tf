provider "aws" {
  # Configuration options
  region = "us-east-2"
}

resource "aws_instance" "example"{
    ami = "ami-0b4624933067d393a"
    instance_type = "t3.micro"
    
    tags = {
        Name = "terraform-example"
    }
}

