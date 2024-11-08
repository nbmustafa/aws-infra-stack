resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Public Subnets
resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/26"
  map_public_ip_on_launch = true
  availability_zone = "eu-central-1a"
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.64/26"
  map_public_ip_on_launch = true
  availability_zone = "eu-central-1b"
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.128/26"
  map_public_ip_on_launch = true
  availability_zone = "eu-central-1c"
}

# Private Compute Subnets
resource "aws_subnet" "private_compute_subnet_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/26"
  availability_zone = "eu-central-1a"
}

resource "aws_subnet" "private_compute_subnet_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.64/26"
  availability_zone = "eu-central-1b"
}

resource "aws_subnet" "private_compute_subnet_c" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.128/26"
  availability_zone = "eu-central-1c"
}

# Private DB Subnets
resource "aws_subnet" "private_db_subnet_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/26"
  availability_zone = "eu-central-1a"
}

resource "aws_subnet" "private_db_subnet_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.64/26"
  availability_zone = "eu-central-1b"
}

resource "aws_subnet" "private_db_subnet_c" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.128/26"
  availability_zone = "eu-central-1c"
}

# IGW and Routing tables
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_subnet_association_a" {
  subnet_id = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association_b" {
  subnet_id = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association_c" {
  subnet_id = aws_subnet.public_subnet_c.id
  route_table_id = aws_route_table.public_route_table.id
}

### Security Groups 
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebSG"
  }
}

resource "aws_security_group" "private_compute_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      aws_subnet.public_subnet_a.cidr_block,
      aws_subnet.public_subnet_b.cidr_block,
      aws_subnet.public_subnet_c.cidr_block
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PrivateComputeSG"
  }
}

resource "aws_security_group" "private_db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [
      aws_subnet.private_compute_subnet_a.cidr_block,
      aws_subnet.private_compute_subnet_b.cidr_block,
      aws_subnet.private_compute_subnet_c.cidr_block
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PrivateDBSG"
  }
}

# Applying NACLs on all subnets:
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id

  # Allow inbound HTTPS traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0" //Change this to cloudflare IP address/range
    from_port  = 443
    to_port    = 443
  }

  # Allow outbound traffic to anywhere
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_network_acl_association" "public_a" {
  subnet_id     = aws_subnet.public_subnet_a.id
  network_acl_id = aws_network_acl.public.id
}

resource "aws_network_acl_association" "public_b" {
  subnet_id     = aws_subnet.public_subnet_b.id
  network_acl_id = aws_network_acl.public.id
}

resource "aws_network_acl_association" "public_c" {
  subnet_id     = aws_subnet.public_subnet_c.id
  network_acl_id = aws_network_acl.public.id
}

resource "aws_network_acl" "private_compute" {
  vpc_id = aws_vpc.main.id

  # Allow inbound traffic from public subnets
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_subnet.public_subnet_a.cidr_block
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_subnet.public_subnet_b.cidr_block
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_subnet.public_subnet_c.cidr_block
    from_port  = 443
    to_port    = 443
  }

  # Allow outbound traffic to private DB subnets
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_network_acl_association" "private_compute_a" {
  subnet_id     = aws_subnet.private_compute_subnet_a.id
  network_acl_id = aws_network_acl.private_compute.id
}

resource "aws_network_acl_association" "private_compute_b" {
  subnet_id     = aws_subnet.private_compute_subnet_b.id
  network_acl_id = aws_network_acl.private_compute.id
}

resource "aws_network_acl_association" "private_compute_c" {
  subnet_id     = aws_subnet.private_compute_subnet_c.id
  network_acl_id = aws_network_acl.private_compute.id
}

resource "aws_network_acl" "private_db" {
  vpc_id = aws_vpc.main.id

  # Allow inbound MySQL traffic from private compute subnets
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_subnet.private_compute_subnet_a.cidr_block
    from_port  = 3306
    to_port    = 3306
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = aws_subnet.private_compute_subnet_b.cidr_block
    from_port  = 3306
    to_port    = 3306
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = aws_subnet.private_compute_subnet_c.cidr_block
    from_port  = 3306
    to_port    = 3306
  }

  # Allow outbound traffic to anywhere
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_network_acl_association" "private_db_a" {
  subnet_id      = aws_subnet.private_db_subnet_a.id
  network_acl_id = aws_network_acl.private_db.id
}

resource "aws_network_acl_association" "private_db_b" {
  subnet_id      = aws_subnet.private_db_subnet_b.id
  network_acl_id = aws_network_acl.private_db.id
}

resource "aws_network_acl_association" "private_db_c" {
  subnet_id      = aws_subnet.private_db_subnet_c.id
  network_acl_id = aws_network_acl.private_db.id
}
