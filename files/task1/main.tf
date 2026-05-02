# Fetch the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create a key pair
resource "aws_key_pair" "final_task_key" {
  key_name   = "final_task_key"
  public_key = file(var.ssh_public_key_path)
}

# Security group
resource "aws_security_group" "final_task_sg" {
  name        = "final_task_sg"
  description = "Allow inbound traffic for App and Gateway"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Custom SSH (Task 3)"
    from_port   = 6969
    to_port     = 6969
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all internal traffic within the security group
  ingress {
    description = "Internal Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Gateway Instance
resource "aws_instance" "gateway" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.final_task_key.key_name

  vpc_security_group_ids = [aws_security_group.final_task_sg.id]

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "Gateway"
  }
}

# Appserver 1 (k3s Master)
resource "aws_instance" "appserver_1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  key_name      = aws_key_pair.final_task_key.key_name

  vpc_security_group_ids = [aws_security_group.final_task_sg.id]

  root_block_device {
    volume_size = 15
    volume_type = "gp3"
  }

  tags = {
    Name = "Appserver 1"
  }
}

# Appserver 2 (k3s Worker 1)
resource "aws_instance" "appserver_2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "c7i-flex.large"
  key_name      = aws_key_pair.final_task_key.key_name

  vpc_security_group_ids = [aws_security_group.final_task_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "Appserver 2"
  }
}

# Appserver 3 (k3s Worker 2)
resource "aws_instance" "appserver_3" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "c7i-flex.large"
  key_name      = aws_key_pair.final_task_key.key_name

  vpc_security_group_ids = [aws_security_group.final_task_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "Appserver 3"
  }
}

# Elastic IPs
resource "aws_eip" "gateway_eip" {
  instance = aws_instance.gateway.id
  domain   = "vpc"
}

resource "aws_eip" "appserver_1_eip" {
  instance = aws_instance.appserver_1.id
  domain   = "vpc"
}

resource "aws_eip" "appserver_2_eip" {
  instance = aws_instance.appserver_2.id
  domain   = "vpc"
}

resource "aws_eip" "appserver_3_eip" {
  instance = aws_instance.appserver_3.id
  domain   = "vpc"
}
