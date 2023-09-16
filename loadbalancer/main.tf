resource "aws_vpc" "mvpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        "Name" = "myvpc"
    }
  
}

resource "aws_subnet" "sub1" {
    vpc_id = aws_vpc.mvpc.id
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-2a"
    tags = {
      "Name" = "mysub1" 
    }
}
resource "aws_subnet" "sub2" {
    vpc_id = aws_vpc.mvpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-2b"
    tags = {
      "Name" = "mysub2" 
    }
  
}
resource "aws_internet_gateway" "myig" {
    vpc_id = aws_vpc.mvpc.id
    tags = {
      "Name" = "myigw" 
    }
  
}
resource "aws_route_table" "myrtb" {
    vpc_id = aws_vpc.mvpc.id
    route {
        gateway_id = aws_internet_gateway.myig.id
        cidr_block = "0.0.0.0/0"
    }
  tags = {
    "Name" = "rtgw"
  }
}
resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.sub1.id
    route_table_id = aws_route_table.myrtb.id
  
}
resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.sub2.id
    route_table_id = aws_route_table.myrtb.id
  
}

resource "aws_security_group" "mysg" {

  vpc_id = aws_vpc.mvpc.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "Apache2" {
    ami = "ami-01103fb68b3569475"
    instance_type = "t2.micro"
    user_data = file("apache.sh")
    
    vpc_security_group_ids = [ aws_security_group.mysg.id]
    subnet_id = aws_subnet.sub1.id
    tags = {
      "Name" = "apache2" 
    }
    
}

resource "aws_instance" "ngnix" {
    ami = "ami-01103fb68b3569475"
    instance_type = "t2.micro"
    user_data = file("ngnix.sh")
    subnet_id = aws_subnet.sub2.id
    vpc_security_group_ids = [ aws_security_group.mysg.id]
    tags = {
      "Name" = "ngnix"
    }
  
}

resource "aws_lb_target_group" "mytg" {
    name = "tg-for-twoserver"
    
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.mvpc.id
    health_check {
      protocol = "HTTP"
      path = "/" 
      port = "traffic-port"

    }
  
}

resource "aws_lb" "myelb" {
  name = "myelb"
  internal = "false"
  load_balancer_type = "application"
  security_groups = [ aws_security_group.mysg.id ]
  subnets = [ aws_subnet.sub1.id , aws_subnet.sub2.id ]

   tags = {
     "Name" = "My-application-loadbalacer" 
   }
  
}

resource "aws_lb_target_group_attachment" "mytga" {
    target_group_arn = aws_lb_target_group.mytg.arn
    target_id = aws_instance.Apache2.id
    port = 80
  
}

resource "aws_lb_target_group_attachment" "mytgaa" {
    target_group_arn = aws_lb_target_group.mytg.arn
    target_id = aws_instance.ngnix.id
    port = 80
  
}


resource "aws_lb_listener" "mylnr" {
    load_balancer_arn = aws_lb.myelb.arn
    port = 80
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.mytg.arn
  
    }
  
}


