// Line 10 : Recommended for now to specify boolean values for variables as the strings "true" and "false" 

resource "aws_key_pair" "web_admin" {
  key_name = "web_admin"
  public_key = file("~/.ssh/web_admin.pub")
}

resource "aws_vpc" "terra_VPC" {
  cidr_block = "20.0.0.0/16"
  enable_dns_hostnames = "true" 
  
  tags = {
    Name = "terra_VPC"
  }
}

resource "aws_subnet" "terra_public_subnet" {
  vpc_id = aws_vpc.terra_VPC.id
  cidr_block = "20.0.1.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "terra_public_subnet"
  }
}

resource "aws_subnet" "terra_private_subnet" {
  vpc_id = aws_vpc.terra_VPC.id
  cidr_block = "20.0.2.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "terra_private_subnet"
  }
}

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.terra_VPC.id

  tags = {
    Name = "terra_IGW"
  }
}

resource "aws_eip" "EIP" {
  vpc = true
}

resource "aws_nat_gateway" "NGW" {
  allocation_id = aws_eip.EIP.id
  subnet_id = aws_subnet.terra_public_subnet.id

  tags = {
    Name = "NGW"
  }
}

resource "aws_route_table" "pub_route" {
  vpc_id = aws_vpc.terra_VPC.id
  route {
    cidr_block = "::/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Name = "terra_pub_route"
  }
}

resource "aws_route_table_association" "pub_route_association" {
  subnet_id = aws_subnet.terra_public_subnet.id
  route_table_id = aws_route_table.pub_route.id
}

resource "aws_route_table" "pri_route" {
  vpc_id = aws_vpc.terra_VPC.id
  route {
    cidr_block = "::/0"
    gateway_id = aws_internet_gateway.NGW.id
  }

  tags = {
    Name = "terra_pri_route"
  }
}

resource "aws_route_table_association" "pri_route_association" {
  subnet_id = aws_subnet.terra_private_subnet.id
  route_table_id = aws_route_table.pri_route.id
}

resource "aws_security_group" "pri_sg" {
  name = "SSH, HTTP"
  description = "Allow SSH, HTTP port from all"
  vpc_id = aws_vpc.terra_VPC.id
  ingress {
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
}

