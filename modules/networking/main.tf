# main.tf — Networking capability
#
# WHAT THIS MODULE ACTUALLY GIVES A CONSUMING TEAM:
#   - A VPC
#   - N public subnets (one per AZ) with a route to the internet
#   - N private subnets (one per AZ) with NO direct internet route
#   - An Internet Gateway (for public subnets)
#   - A NAT Gateway (for private subnets to reach out, optional)
#   - Route tables wired up correctly for all of the above
#   - A baseline "default deny inbound" security group teams can extend
#
# This is the difference between a "real abstraction" and a thin wrapper:
# a team calling this module gets a working, secure network with ~5
# variables instead of hand-writing ~15 resource blocks and getting the
# routing wrong (a VERY common mistake — e.g. forgetting a NAT route and
# wondering why private EC2 instances can't download packages).

locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner_team
    ManagedBy   = "terraform"
    Platform    = "cob"
  }
}

# Ask AWS which Availability Zones exist in this region, so we don't
# hardcode AZ names (hardcoding breaks the module if someone uses it
# in a different region).
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# --- PUBLIC SUBNETS ---
# cidrsubnet() automatically carves out non-overlapping ranges from the
# VPC CIDR, one per AZ, so we don't hand-type CIDR math.
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-${data.aws_availability_zones.available.names[count.index]}"
    Tier = "public"
  })
}

# --- PRIVATE SUBNETS ---
# Offset by 100 in the cidrsubnet index so public/private ranges never collide.
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + var.az_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-${data.aws_availability_zones.available.names[count.index]}"
    Tier = "private"
  })
}

# --- NAT GATEWAY (optional, for private subnet outbound internet) ---
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip"
  })
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id # NAT lives in a public subnet

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.this]
}

# --- ROUTING: PUBLIC ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- ROUTING: PRIVATE ---
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[0].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# --- BASELINE SECURITY GROUP ---
# Deny-by-default. Consuming modules (compute, RDS) add their own
# specific ingress rules on top of / instead of this — this just
# establishes "nothing is open unless someone deliberately opens it."
resource "aws_security_group" "default_deny" {
  name        = "${local.name_prefix}-default-deny"
  description = "Baseline SG: no inbound by default, all outbound allowed"
  vpc_id      = aws_vpc.this.id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-default-deny"
  })
}
