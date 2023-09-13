terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>5.0"
    }
  }
}

provider "aws" {
  
    region =  ""
    access_key = ""
    secret_key = ""

  
} 

resource "aws_vpc" "assignment_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" =  "assignment_vpc"
  }
}

resource "aws_subnet" "assignment_subnet" {
  cidr_block = "10.0.10.0/24"
  vpc_id = aws_vpc.assignment_vpc.id
  availability_zone = "us-east-2b"
  tags = {
    "Name" = "assignment_subnet"
  }  
}

resource "aws_internet_gateway" "internet_for_assignment" {
  vpc_id = aws_vpc.assignment_vpc.id
  tags = {
    "Name" = "assignment_internet" 
  }
  
}
resource "aws_default_route_table" "assignment_default" {
  default_route_table_id = aws_vpc.assignment_vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_for_assignment.id

  }
  tags = {
    "Name" = "internet_routing"
  }
}

resource "aws_default_security_group" "assignment_security_group" {
  vpc_id = aws_vpc.assignment_vpc.id
      ingress  {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
 
  egress  {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "assignment_instance" {
  ami = "ami-01103fb68b3569475"     #ubuntu ami 
  instance_type = "t2.micro"
  subnet_id = aws_subnet.assignment_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_default_security_group.assignment_security_group.id]
  
  
  user_data = <<-EOF
#!/bin/bash
sudo yum -y update
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo "<h1>Deployed by Terraform</h1>" > /var/www/html/index.html
EOF

   
  tags = {
    "Name" = "ubuntu_instance" 
  }
    
}
  

