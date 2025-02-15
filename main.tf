provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "TerraformVPC"
  }
}

resource "aws_subnet" "publicsubnet" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/28"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "privatesubnet" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.128/28"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "new-igw"
  }
}

resource "aws_route_table" "publicroutetable" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "privateroutetable" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table_association" "rtpublic" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.publicroutetable.id
}

resource "aws_route_table_association" "rtprivate" {
  subnet_id      = aws_subnet.privatesubnet.id
  route_table_id = aws_route_table.privateroutetable.id
}

resource "aws_security_group" "sg1" {
  name   = "sg1"
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "sg1"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress1" {
  security_group_id = aws_security_group.sg1.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "engress1" {
  security_group_id = aws_security_group.sg1.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


resource "aws_instance" "ec1" {
  ami                    = "ami-04b4f1a9cf54c11d0"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.publicsubnet.id
  vpc_security_group_ids = [aws_security_group.sg1.id]
  key_name               = "jumpserverkeypair"
  tags = {
    Name = "PublicEC2"
  }
}

resource "aws_instance" "ec2" {
  ami                         = "ami-04b4f1a9cf54c11d0"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.privatesubnet.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.sg1.id]
  key_name                    = "ec2keypair"
  tags = {
    Name = "PrivateEC2"
  }
}
