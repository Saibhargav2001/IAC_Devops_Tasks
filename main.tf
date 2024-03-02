provider "aws" {
  region     = "us-west-2"
  profile = "myaws"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_security_group" "Task1_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "my_lb" {
  name               = "Task1-LoadBalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Task1_sg.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

resource "aws_autoscaling_group" "my_asg" {
  name                 = "Task1_asg"
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  launch_template {
    id      = aws_launch_template.my_lt.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "my_lt" {
  name_prefix   = "Task1_lt"
  image_id      = "ami-052c9ea013e6e3567"
  instance_type = "t2.micro"
  key_name      = "my_devops_key"
  vpc_security_group_ids = [aws_security_group.Task1_sg.id]
  user_data     = base64encode(<<-EOF
                  #!/bin/bash
                  echo "Hello, World!" > index.html
                  nohup python -m SimpleHTTPServer 80 &
                  EOF
                )
}

resource "aws_db_instance" "my_db" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  identifier           = "mydb"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  publicly_accessible  = true
  skip_final_snapshot  = true
}
