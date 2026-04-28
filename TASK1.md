# Task 1: Provisioning

**Requirement :**

- Local machine w/ Ansible & Terraform

- Cloud Computing Servers
  
  - Appserver
  
  - Gateway

- Other Servers if Required

**Instructions :**

- Attach SSH keys & IP configuration to all VMs

- All Server Configuration using Ansible

---

# I. Terraform and Ansible Installation

1. Install WSL (Windows Subsystem for Linux) Ubuntu first if you don't have it.
   
   ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-23-40-image.png)

2. Install Terraform and Ansible inside WSL.
   
   - For Terraform, run:
     
     ```bash
     wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
     echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
     sudo apt update && sudo apt install terraform
     ```
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-28-53-image.png)
     
     Then run `terraform --version` to verify it's version.
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-29-21-image.png)
   
   - For Ansible, just run `sudo apt install ansible -y` to install it. Then run `ansible --version` to verify it's version.
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-30-30-image.png)
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-30-33-image.png)

# II. AWS Preparation & SSH

1. We can create a new IAM Account in AWS so that Terraform can access our EC2.
   
   - First, click on IAM > IAM users > Create user. On the first page (*Specify user details*) you can fill the *user name* as needed. For this one, I filled it with `terraform-user`. After that, click *Next*.
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-37-34-image.png)
   
   - In the *Set permissions* page, choose "*Attach policies directly*" and search for ***"AmazonEC2FullAccess"*** (this is chosen so that Terraform can manage EC2 instances on AWS). After that, click *Next* button and on the next page just click *Create account*.
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-40-24-image.png)
   
   - In the *IAM users* page, click on the new account that was just been made.
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-42-18-image.png)
   
   - Once inside, click “Create access key” (highlighted below).
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-42-39-image.png)
   
   - On the “*Access key best practice & alternatives*” page, select the use case for ***Command Line Interface (CLI)*** and check the confirmation box below it, then click the *Next* button.
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-44-58-image.png)
   
   - On the next page, you could enter a description of the access key that you'll create, then click “*Create access key*”. In this case, I fill it with "*terraform-access*".
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-46-27-image.png)
   
   - Next, a page will appear informing us that the access key has been created. ***SAVE THE ACCESS KEY BY CLICKING "download .csv file"! BECAUSE THIS ACCESS KEY WILL ONLY BE DISPLAYED ONCE!*** Once done, click the "*Done*" button.
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-48-28-image.png)

2. We then setup AWS CLI V2. 
   
   - Because I'm using an `aarch64` device, I'll install that version.
     
     ```bash
     sudo apt-get update && sudo apt-get install curl unzip -y
     curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
     unzip awscliv2.zip
     sudo ./aws/install
     # Verify installation
     aws --version
     ```
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-55-01-image.png)
   
   - After that, run `aws configure` to connect this device to AWS. Fill the information from the access key that just created.
     
     ```plaintext
     AWS Access Key ID: (Enter your Key ID)
     AWS Secret Access Key: (Enter your Secret Key)
     Default region name: ap-southeast-3 (Jakarta) or ap-southeast-1 (Singapore)
     Default output format: (just press enter)
     ```
   
   - Then, run `aws sts get-caller-identity` to verify.
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-19-57-27-image.png) 

3. Instead of creating the key pair manually in AWS Console, we generate it locally. This is cleaner because Terraform will manage the key pair lifecycle automatically.
   
   - First, create a new directory for the ssh to be placed. For this one, I run `mkdir ~/automation/ssh` to create `~/automation/ssh` . Then, inside it, I run:
     
     ```bash
     ssh-keygen -t rsa -b 4096 -f ~/automation/ssh/finaltask-key
     ```
     
     This generates two files at once: 
     
     - `finaltask-key`         → private key (used for SSH access) 
     
     - `finaltask-key.pub` → public key (Terraform uploads this to AWS)
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-20-02-51-image.png)
   
   - Set correct permissions on the private key with `chmod 400 ~/automation/ssh/finaltask-key/` . Why? So that the file can only be accessible by its owner.
     
     ![](C:\Users\Rizal\AppData\Roaming\marktext\images\2026-04-27-20-03-57-image.png)

# III. Terraform's Configs & Run

To run, Terraform requires several `plans` and `configuration files`. The file structure is as follows:

```plaintext
~/automation/terraform/
   ├── providers.tf       → AWS provider + credentials
   ├── variables.tf       → variable declarations + defaults
   ├── main.tf            → actual infrastructure resources
   ├── outputs.tf         → prints IPs after apply
   ├── terraform.tfvars   → your actual credentials
   └── .gitignore         → protects sensitive files
```

For the scripts of each `.tf` files, look below.

<details>
    <summary>providers.tf</summary>

```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
```

</details>

<details>
    <summary>variables.tf</summary>

```terraform
# ==========================================
# REGION VARIABLE
# ==========================================
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-southeast-3"
}

# ==========================================
# AWS CREDENTIALS
# ==========================================
variable "aws_access_key" {
  description = "AWS IAM access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS IAM secret key"
  type        = string
  sensitive   = true
}

# ==========================================
# SSH KEY NAME VARIABLE
# ==========================================
variable "key_name" {
  description = "Name of the SSH key pair in AWS"
  type        = string
  default     = "finaltask-key"
}

# ==========================================
# NETWORKING
# ==========================================
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# ==========================================
# INSTANCE TYPES
# ==========================================
variable "gateway_instance_type" {
  description = "Instance type for Gateway server"
  type        = string
  default     = "t3.micro"
}

variable "appserver1_instance_type" {
  description = "Instance type for Appserver 1 (k3s Master)"
  type        = string
  default     = "t3.small"
}

variable "appserver2_instance_type" {
  description = "Instance type for Appserver 2 (k3s Worker 1)"
  type        = string
  default     = "c7i-flex.large"
}

variable "appserver3_instance_type" {
  description = "Instance type for Appserver 3 (k3s Worker 2)"
  type        = string
  default     = "c7i-flex.large"
}

# ==========================================
# STORAGE SIZES (in GB)
# ==========================================
variable "gateway_disk_size" {
  description = "Root disk size for Gateway"
  type        = number
  default     = 8
}

variable "appserver1_disk_size" {
  description = "Root disk size for Appserver 1"
  type        = number
  default     = 15
}

variable "appserver2_disk_size" {
  description = "Root disk size for Appserver 2"
  type        = number
  default     = 20
}

variable "appserver3_disk_size" {
  description = "Root disk size for Appserver 3"
  type        = number
  default     = 20
}
```

</details>

<details>
    <summary>main.tf</summary>

```terraform
# ==========================================
# 1. DATA SOURCE (Auto-fetch Ubuntu 22.04)
# ==========================================

# Automatically searches for the latest official Ubuntu 22.04 AMI ID.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Official AWS account ID for Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# ==========================================
# 2. NETWORKING (Core Network Infrastructure)
# ==========================================

# A VPC acts as an isolated private network for all our servers.
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "finaltask-vpc" }
}

# A Subnet is a subdivision inside the VPC where the servers will reside.
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags                    = { Name = "finaltask-public-subnet" }
}

# An Internet Gateway acts as a door allowing traffic to reach the internet.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = { Name = "finaltask-igw" }
}

# A Route Table dictates where network traffic should be directed.
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "finaltask-public-rt" }
}

# Links the Subnet to the Route Table.
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


# ==========================================
# 3. FIREWALL (Security Groups)
# ==========================================

# Security group for the Gateway server.
resource "aws_security_group" "gateway_sg" {
  name        = "finaltask-gateway-id"
  description = "Security group for Gateway server"
  vpc_id      = aws_vpc.main_vpc.id

  # SSH (default port - temporary for initial Ansible setup)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH (custom port)
  ingress {
    from_port   = 6969
    to_port     = 6969
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "finaltask-gateway-id" }
}

# Security group for all Appservers.
resource "aws_security_group" "appserver_sg" {
  name        = "finaltask-appserver-id"
  description = "Security group for Appserver"
  vpc_id      = aws_vpc.main_vpc.id

  # SSH (default port - temporary for initial Ansible setup)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH (custom port)
  ingress {
    from_port   = 6969
    to_port     = 6969
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Frontend App
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Backend API
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus Node Exporter
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "finaltask-appserver-id" }
}


# ==========================================
# 4. SSH KEY PAIR (Authentication)
# ==========================================

# Registers the existing public key with AWS.
resource "aws_key_pair" "finaltask" {
  key_name   = var.key_name
  public_key = file("../ssh/finaltask-key.pub")
}


# ==========================================
# 5. COMPUTE (EC2 Instances)
# ==========================================

# Gateway Server - Reverse proxy, SSL, NGINX
resource "aws_instance" "gateway" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.gateway_instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.gateway_sg.id]
  key_name               = aws_key_pair.finaltask.key_name

  root_block_device {
    volume_size = var.gateway_disk_size
    volume_type = "gp3"
  }

  tags = { Name = "finaltask-gateway" }
}

# Appserver 1 - Staging + Production app / future k3s Master
resource "aws_instance" "appserver1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.appserver1_instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.appserver_sg.id]
  key_name               = aws_key_pair.finaltask.key_name

  root_block_device {
    volume_size = var.appserver1_disk_size
    volume_type = "gp3"
  }

  tags = { Name = "finaltask-appserver1" }
}

# Appserver 2 - Staging + Production app / future k3s Worker 1
resource "aws_instance" "appserver2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.appserver2_instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.appserver_sg.id]
  key_name               = aws_key_pair.finaltask.key_name

  root_block_device {
    volume_size = var.appserver2_disk_size
    volume_type = "gp3"
  }

  tags = { Name = "finaltask-appserver2" }
}

# Appserver 3 - Staging + Production app / future k3s Worker 2
resource "aws_instance" "appserver3" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.appserver3_instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.appserver_sg.id]
  key_name               = aws_key_pair.finaltask.key_name

  root_block_device {
    volume_size = var.appserver3_disk_size
    volume_type = "gp3"
  }

  tags = { Name = "finaltask-appserver3" }
}


# ==========================================
# 6. STATIC IPs (Elastic IPs)
# ==========================================

# Static IP for Gateway
resource "aws_eip" "gateway_eip" {
  instance = aws_instance.gateway.id
  domain   = "vpc"
  tags     = { Name = "finaltask-gateway-eip" }
}

# Static IP for Appserver 1
resource "aws_eip" "appserver1_eip" {
  instance = aws_instance.appserver1.id
  domain   = "vpc"
  tags     = { Name = "finaltask-appserver1-eip" }
}

# Static IP for Appserver 2
resource "aws_eip" "appserver2_eip" {
  instance = aws_instance.appserver2.id
  domain   = "vpc"
  tags     = { Name = "finaltask-appserver2-eip" }
}

# Static IP for Appserver 3
resource "aws_eip" "appserver3_eip" {
  instance = aws_instance.appserver3.id
  domain   = "vpc"
  tags     = { Name = "finaltask-appserver3-eip" }
}


# ==========================================
# 7. BLOCK STORAGE (Extra EBS Volumes)
# ==========================================

# Extra storage for Appserver 1
resource "aws_ebs_volume" "appserver1_vol" {
  availability_zone = "${var.aws_region}a"
  size              = var.appserver1_disk_size
  type              = "gp3"
  tags              = { Name = "finaltask-appserver1-vol" }
}

# Extra storage for Appserver 2
resource "aws_ebs_volume" "appserver2_vol" {
  availability_zone = "${var.aws_region}a"
  size              = var.appserver2_disk_size
  type              = "gp3"
  tags              = { Name = "finaltask-appserver2-vol" }
}

# Extra storage for Appserver 3`
resource "aws_ebs_volume" "appserver3_vol" {
  availability_zone = "${var.aws_region}a"
  size              = var.appserver3_disk_size
  type              = "gp3"
  tags              = { Name = "finaltask-appserver3-vol" }
}

# Attach extra volume to Appserver 1
resource "aws_volume_attachment" "appserver1_vol_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.appserver1_vol.id
  instance_id = aws_instance.appserver1.id
}

# Attach extra volume to Appserver 2
resource "aws_volume_attachment" "appserver2_vol_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.appserver2_vol.id
  instance_id = aws_instance.appserver2.id
}

# Attach extra volume to Appserver 3
resource "aws_volume_attachment" "appserver3_vol_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.appserver3_vol.id
  instance_id = aws_instance.appserver3.id
}
```

</details>

<details>
    <summary>outputs.tf</summary>

```terraform
output "gateway_public_ip" {
  description = "Public IP of Gateway server"
  value       = aws_eip.gateway_eip.public_ip
}

output "appserver1_public_ip" {
  description = "Public IP of Appserver 1 (k3s Master)"
  value       = aws_eip.appserver1_eip.public_ip
}

output "appserver2_public_ip" {
  description = "Public IP of Appserver 2 (k3s Worker 1)"
  value       = aws_eip.appserver2_eip.public_ip
}

output "appserver3_public_ip" {
  description = "Public IP of Appserver 3 (k3s Worker 2)"
  value       = aws_eip.appserver3_eip.public_ip
}

```

</details>

<details>
    <summary>terraform.tfvars</summary>

```terraform
aws_access_key = "myaccesskey"
aws_secret_key = "mysecretkey"
```

</details>

<details>
    <summary>.gitignore</summary>

```git
# Ignore credential files
terraform.tfvars

# Ignore Terraform state files (contain sensitive data)
*.tfstate
*.tfstate.backup

# Ignore Terraform cache directory
.terraform/
```

</details>

<img width="1466" height="79" alt="image" src="https://github.com/user-attachments/assets/c5a5b80c-15d8-4e30-9592-90554e087c8d" />
*Inside of Terraform's directory (plus a tfstate files that has been generated after Terraform run)* <br>

- Run `terraform init` to start initialize Terraform
  <img width="975" height="526" alt="image" src="https://github.com/user-attachments/assets/3051bf33-6390-453c-8c7f-cbc3bc466ccd" />
  
- After it's done, verify the plans again with `terraform plan`.
  <img width="975" height="589" alt="image" src="https://github.com/user-attachments/assets/814f48e8-86fa-4554-bbad-40ce9a0bae3f" />
  
- When already sure about the plans, run `terraform apply`.
  <img width="975" height="726" alt="image" src="https://github.com/user-attachments/assets/d5a1cd76-6820-42e0-b9eb-13a7d03051fd" />
  
- When done, the servers can be verified in AWS.
  <img width="975" height="111" alt="image" src="https://github.com/user-attachments/assets/5ee76dd8-a732-499f-bc1d-a0825fffa002" />

  
