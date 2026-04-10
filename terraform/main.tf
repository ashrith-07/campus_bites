

# Fetch the latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Default VPC Configuration (assumes default VPC is available in account, typical for simple deployments)
data "aws_vpc" "default" {
  default = true
}

# Create a Security Group
resource "aws_security_group" "campus_bites_sg" {
  name        = "campus-bites-sg"
  description = "Security group for Campus Bites deployment allowing SSH and web access"
  vpc_id      = data.aws_vpc.default.id

  # Allow SSH
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Frontend access
  ingress {
    description = "Frontend from anywhere"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Backend API access
  ingress {
    description = "Backend from anywhere"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "campus-bites-sg"
  }
}

# Launch the EC2 Instance
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small" # Using t3.small for running both node apps + DB connections

  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.campus_bites_sg.id]

  # Provision 20 GB gp3 storage
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "campus-bites-server"
  }
}

# Output the Instance Public IP
output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}


