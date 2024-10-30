variable "region" {
 default = "ap-south-1"
}


variable "vpccidr_block" {
 default = "192.168.0.0/16"
}


variable "sgname" {
 default = "allow_tls"
}

variable "aws_lb" {
  default = "load-balancer"
}


variable "awskeypair" {
 default = "deployer-key"
}


variable "aws_ebs_volume" {
 default = "ap-south-1a"
}


variable "instance_type" {
 default = "t2.medium"
}


variable "public_subnet" {
  default = {
          Name = "Public-Subnet"
          cidr_block = "192.168.1.0/24"
          availability_zone = "ap-south-1a"
      }
}

variable "private_subnet" {
  default = {
          Name = "Private-Subnet"
          cidr_block = "192.168.2.0/24"
          availability_zone = "ap-south-1b"
      }
}

variable "aws_internet_gateway" {
  default = {
    Name = "IGW"
  }
}

variable "aws_route_table" {
  default = "IGW-RT"
}


variable "aws_route_table_association" {
  default = "publicsubnetRT"
}

variable "aws_security_group" {
  default = "SG"
}



variable "aws_launch_configuration" {
  default = {
    name = "Launch-Configuration"
  }
}


variable "aws_instance" {
    default = {
        ami = "ami-04125d804acca5692"
        instance_type = "t2.micro"
      
        ami = "ami-04125d804acca5692"
        instance_type = "t2.micro"
    }
}

variable "aws_autoscaling_group" {
  default = {
    name = "Auto-Scaling-Group"
  }
}

