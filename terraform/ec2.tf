# Define the Launch Template
resource "aws_launch_template" "web" {
  name_prefix   = "${local.organisation}-web-"
  image_id      = "ami-0c55b159cbfafe1f0" # Replace with your desired AMI ID
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.private_compute_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              EOF

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${local.organisation}-web-instance"
    }
  }
}

# Create the Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  min_size         = 1
  max_size         = 3
  desired_capacity = 1
  vpc_zone_identifier = [
    aws_subnet.private_compute_subnet_a.id,
    aws_subnet.private_compute_subnet_b.id,
    aws_subnet.private_compute_subnet_c.id
  ]

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${local.organisation}-web"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
