# Configure the AWS provider
provider "aws" {
  region = "us-east-1" # Update with your desired region
}

# Create a key pair for SSH access
resource "aws_key_pair" "jenkins_key" {
  public_key = file("id_rsa.pub") # Replace with your public key path
  tags = {
    name = "jenkins-key"
  }
}

# Create a security group to allow SSH and Jenkins port access
resource "aws_security_group" "jenkins_sg" {
  name = "jenkins-security-group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["75.7.5.68/32"] # Replace with your IP address
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Update access for Jenkins port (optional)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "jenkins-sg"
  }
}

# Create an EC2 instance
resource "aws_instance" "jenkins_server" {
  ami                    = "ami-04e5276ebb8451442" # Replace with a Jenkins-compatible AMI
  instance_type          = "t2.micro"              # Update with desired instance type
  key_name               = aws_key_pair.jenkins_key.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  # User data script to install Docker and run Jenkins container
  user_data = <<EOF
#!/bin/bash

yum update -y
yum install docker -y
systemctl start docker
systemctl enable docker

docker run -d -p 8080:8080 jenkins/jenkins
EOF
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "New VPC"
  }
}

# Create a network interface
resource "aws_network_interface" "eni" {
  subnet_id = aws_subnet.public.id # Replace with your subnet ID

  # Optional: Assign a private IP address
  private_ips = ["10.10.2.10"]

  # Optional: Set a description
  description = "New Network interface for my instance"
}

# Create a subnet (not included here, but referenced in the ENI)
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public Subnet"
  }
}