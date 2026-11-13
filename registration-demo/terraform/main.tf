terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "guru_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCSNGu1Xl7Pg/8zHpOewo8Zv+EsfViZcYN2WFiKLYOl+M7KXFNW25PULENg6l3PR+zeRlagvzbTpU2F65RWdawlhqSnoEWyMCQdSosbMBOzLfsG+PTopK5ZsixRgeVjHGCAki+ucfMnxZBzkpbE+8q/OQhQpXTuxWRoT4khcrFAFwLQ1a1gqjdhl7vcuJhU1i/aF2GOi5cQPUOhptA4Kb7oRyVgqfy1+L/cw9oKE1nbXwOi13xNSh+1a4KtLD6PNzbHBeCYwwERQDOfXe3zBMmNGTVr61mZjnSXUf3KaaR97sF/cTKSgaubcWJCATPwzDBYkar/XhtSjeJPJq1mYFCmYXkzodijuHnLYLRoI9lOQJr2I7ILoNfwOmLPSDFRsNEXh0Y27bfzoZdNuX7BKVfBp89Akp7GXAQrN9zP1iniSNA8da/u4a9mFMFOcN5S2jXDcMlReK54e5rTRx9LSI5n1sJMi7Qsmoqkxkx3EPSUS2lEiZh2MUI9vKsLlu2/uL8= guruy@Gurraiah"
}
resource "aws_vpc" "my_vpc" {
  cidr_block           = "172.20.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "my_vpc"
  }
}

# ------------------------- SUBNET -------------------------

resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "172.20.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "my_subnet"
  }
}

# ------------------------- INTERNET GATEWAY -------------------------

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_igw"
  }
}

# ------------------------- ROUTE TABLE -------------------------

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ------------------------- JENKINS SECURITY GROUP -------------------------

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "sg_jenkins"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins_sg"
  }
}

# ------------------------- MYAPP SECURITY GROUP -------------------------

resource "aws_security_group" "myapp_sg" {
  name        = "myapp_sg"
  description = "sg_myapp"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "myapp_sg"
  }
}

# ------------------------- JENKINS INSTANCE -------------------------

resource "aws_instance" "jenkins_instance" {
  ami                         = "ami-09bf9dfeeb1e9adbc"
  instance_type               = "m7i-flex.large"

  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = aws_subnet.my_subnet.id
  associate_public_ip_address = true

  depends_on = [aws_route_table_association.public_rt_assoc]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "Jenkins-From-Terraform"
  }
}


resource "terraform_data" "jenkins_setup" {
  triggers_replace = aws_instance.jenkins_instance.id

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
    host        = aws_instance.jenkins_instance.public_ip
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install java-21-amazon-corretto -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum install jenkins -y",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",
      "sudo yum install wget git maven ansible docker -y",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ec2-user",
      "sudo usermod -aG docker jenkins",
      "sudo chmod 666 /var/run/docker.sock",
      "sudo docker run -d --name sonarqube -p 9000:9000 sonarqube",
      "sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.18.3/trivy_0.18.3_Linux-64bit.rpm"
    ]
  }
}
# ------------------------- MYAPP INSTANCE -------------------------

resource "aws_instance" "myapp" {
  ami                         = "ami-09bf9dfeeb1e9adbc"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.my_subnet.id
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.myapp_sg.id]
  associate_public_ip_address = true

  depends_on = [
    aws_route_table_association.public_rt_assoc
  ]

  tags = {
    Name = "MyApp-From-Terraform"
  }
}
