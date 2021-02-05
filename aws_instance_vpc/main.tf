provider "aws" {
  region = var.region
}

# 1. create a VPC
resource "aws_vpc" "vpc" {
    cidr_block = var.cidr
    tags = {
        "Name" = "production_vpc"
    }
}

# 2. create an internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
      "Name" = "production_igw"
  }  
}

# 3. create public subnet
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.public_cidr
    map_public_ip_on_launch = false
    tags = {
        "Name": "public_subnet"
    }
}


# 4. create a route table
resource "aws_route_table" "route_table" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = var.general_cidr
        gateway_id = aws_internet_gateway.igw.id
    }
    route {
        ipv6_cidr_block =  "::/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        "Name": "route_table"
    }
}


# 5. create a route table association
resource "aws_route_table_association" "route_table_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.route_table.id
}


#6. Security group
resource "aws_security_group" "security_group" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.general_cidr]
  }
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.general_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.general_cidr]
  }

  tags = {
    Name = "allow_ssh"
  }
}

#8. create network interface
resource "aws_network_interface" "ni" {
  subnet_id   = aws_subnet.public_subnet.id
  private_ips = ["10.0.0.50"]
  security_groups = [aws_security_group.security_group.id]
  tags = {
    Name = "network_interface"
  }
}


# 9. create IP address
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.ni.id
  associate_with_private_ip = "10.0.0.50"
  depends_on    = [aws_internet_gateway.igw]
}

# 10 . launch an ec2 instance
resource "aws_instance" "web-server" {
  ami           = var.ami # us-east-1
  instance_type = var.instance_type
  key_name = var.key_name
  user_data = <<-EOF
            #!/bin/bash
            sudo apt-get update -y
            sudo apt-get install apache2 -y
            sudo echo "this is my web server" > /var/www/html/index.html
            sudo systemctl restart apache2
            EOF
  network_interface {
      network_interface_id = aws_network_interface.ni.id
      device_index = 0
  }
  tags = {
      "Name" = "webserver"
  }
}