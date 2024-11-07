resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "web_lc" {
  name          = "web-lc"
  image_id      = "ami-0c55b159cbfafe1f0" # Replace with your preferred AMI ID
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_sg.id]

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y apache2
              sudo systemctl start apache2
              sudo systemctl enable apache2
              EOF
}

resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = 1
  min_size             = 1
  max_size             = 3
  vpc_zone_identifier  = [aws_subnet.private_compute_subnet.id]
  launch_configuration = aws_launch_configuration.web_lc.id

  tag {
    key                 = "Name"
    value               = "web-server"
    propagate_at_launch = true
  }
}
