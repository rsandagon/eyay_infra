provider "aws" {
  region = "us-east-1"  # Replace with your desired region
}

# Create a VPC with public and private subnets
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"  # Replace with your desired AZ

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"  # Replace with a different AZ

  tags = {
    Name = "private-subnet"
  }
}

# Create internet gateway and route table for public subnet
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create security groups
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  description = "Security group for frontend instance"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow public access to port 80
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Security group for backend instance"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 8080  # Assuming the REST API runs on port 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]  # Allow access from frontend SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create public frontend instance
resource "aws_instance" "frontend" {
  ami           = "ami-0c55b159cbfafe1f0"  # Replace with your desired AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
}

# Create private backend instance
resource "aws_instance" "backend" {
  ami           = "ami-0cc6600d3650d2611"  # Replace with your desired AMI (consider using Amazon Linux 2 for its lightweight nature)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  private_ip = "10.0.1.10"  # Assign a static private IP address for easier reference (optional)
}

# Configure frontend to access backend IP
resource "aws_eip" "public_ip" {
  vpc = aws_vpc.my_vpc.id
}

resource "aws_nat_gateway" "nat_gateway" {
  subnet_id = aws_subnet.public_subnet.id

  tags = {
    Name = "my-nat-gateway"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_instance_attachment" "nat_gateway_attachment" {
  instance_id = aws_instance.frontend.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  device_index = 100  # Arbitrary device index for the network interface
}

output "frontend_ip" {
  value = aws_eip.public_ip.public_ip
}

output "backend_ip" {
  value = aws_instance.backend.private_ip
}