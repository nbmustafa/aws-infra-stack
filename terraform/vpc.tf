resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Public Subnets
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/26"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_region.current.name}a"
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.64/26"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_region.current.name}b"
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.128/26"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_region.current.name}c"
}

# Private Compute Subnets
resource "aws_subnet" "private_compute_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/26"
  availability_zone = "${data.aws_region.current.name}a"
}

resource "aws_subnet" "private_compute_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.64/26"
  availability_zone = "${data.aws_region.current.name}b"
}

resource "aws_subnet" "private_compute_subnet_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.128/26"
  availability_zone = "${data.aws_region.current.name}c"
}

# Private DB Subnets
resource "aws_subnet" "private_db_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/26"
  availability_zone = "${data.aws_region.current.name}a"
}

resource "aws_subnet" "private_db_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.64/26"
  availability_zone = "${data.aws_region.current.name}b"
}

resource "aws_subnet" "private_db_subnet_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.128/26"
  availability_zone = "${data.aws_region.current.name}c"
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
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association_c" {
  subnet_id      = aws_subnet.public_subnet_c.id
  route_table_id = aws_route_table.public_route_table.id
}

### Security Groups 
resource "aws_security_group" "web_alb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.cloudflare_ip_range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebSG"
  }
}

resource "aws_security_group" "private_compute_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = concat(
      [
        aws_subnet.public_subnet_a.cidr_block,
        aws_subnet.public_subnet_b.cidr_block,
        aws_subnet.public_subnet_c.cidr_block
      ],
      local.corporate_ip_range
    )
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = concat(
      [
        aws_subnet.private_compute_subnet_a.cidr_block,
        aws_subnet.private_compute_subnet_b.cidr_block,
        aws_subnet.private_compute_subnet_c.cidr_block
      ],
      local.corporate_ip_range
    )
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PrivateComputeSG"
  }
}

resource "aws_security_group" "private_db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [
      aws_subnet.private_compute_subnet_a.cidr_block,
      aws_subnet.private_compute_subnet_b.cidr_block,
      aws_subnet.private_compute_subnet_c.cidr_block
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PrivateDBSG"
  }
}

##############################################
########### NACL on public subnets ###########
##############################################
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id,
    aws_subnet.public_subnet_c.id
  ]
}

# Create NACL ingress rules dynamically for corporate IP ranges
resource "aws_network_acl_rule" "ingress_corporate" {
  for_each = { for i, cidr in local.cloudflare_ip_range : i => cidr }

  network_acl_id = aws_network_acl.public.id
  rule_number    = 1000 + each.key * 10
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = each.value
  from_port      = 443
  to_port        = 443
}

# Define egress rules if needed
resource "aws_network_acl_rule" "egress_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 2000
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

#######################################################
########### NACL on private compute subnets ###########
#######################################################
resource "aws_network_acl" "private_compute" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [
    aws_subnet.private_compute_subnet_a.id,
    aws_subnet.private_compute_subnet_b.id,
    aws_subnet.private_compute_subnet_c.id
  ]
}

# Create NACL ingress rules dynamically for corporate IP ranges
resource "aws_network_acl_rule" "ssh_ingress_from_corporate" {
  for_each = { for i, cidr in local.corporate_ip_range : i => cidr }

  network_acl_id = aws_network_acl.private_compute.id
  rule_number    = 1000 + each.key * 10
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = each.value
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "https_from_ingress_corporate" {
  for_each = { for i, cidr in local.corporate_ip_range : i => cidr }

  network_acl_id = aws_network_acl.private_compute.id
  rule_number    = 2000 + each.key * 10
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = each.value
  from_port      = 443
  to_port        = 443
}

# Additional NACL ingress rules for public subnets
resource "aws_network_acl_rule" "ingress_from_public_a" {
  network_acl_id = aws_network_acl.private_compute.id
  rule_number    = 3000
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = aws_subnet.public_subnet_a.cidr_block
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ingress_from_public_b" {
  network_acl_id = aws_network_acl.private_compute.id
  rule_number    = 3100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = aws_subnet.public_subnet_b.cidr_block
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ingress_from_public_c" {
  network_acl_id = aws_network_acl.private_compute.id
  rule_number    = 3200
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = aws_subnet.public_subnet_c.cidr_block
  from_port      = 443
  to_port        = 443
}

# Define egress rules
resource "aws_network_acl_rule" "egress_all" {
  network_acl_id = aws_network_acl.private_compute.id
  rule_number    = 4000
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

############################################
###########  NACL on db subnets  ###########
############################################
resource "aws_network_acl" "private_db" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [
    aws_subnet.private_db_subnet_a.id,
    aws_subnet.private_db_subnet_b.id,
    aws_subnet.private_db_subnet_c.id
  ]
}

# Additional NACL ingress rules for public subnets
resource "aws_network_acl_rule" "ingress_db_a" {
  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 1000
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = aws_subnet.private_compute_subnet_a.cidr_block
  from_port      = 3306
  to_port        = 3306
}

resource "aws_network_acl_rule" "ingress_db_b" {
  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 2000
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = aws_subnet.private_compute_subnet_b.cidr_block
  from_port      = 3306
  to_port        = 3306
}

resource "aws_network_acl_rule" "ingress_db_c" {
  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 3000
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = aws_subnet.private_compute_subnet_c.cidr_block
  from_port      = 3306
  to_port        = 3306
}

# Define egress rules if needed
resource "aws_network_acl_rule" "egress_all" {
  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 4000
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
