
provider "aws" {
  region  = var.region
  profile = "default"
}


resource "aws_vpc" "main" {
  cidr_block       = var.vpccidr_block
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}


resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.main.id
    availability_zone = "${lookup(var.public_subnet, "availability_zone")}"
    cidr_block = "${lookup(var.public_subnet,"cidr_block")}"
    tags = {
    Name = "${lookup(var.public_subnet,"Name")}"
  }
}

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.main.id
    availability_zone = "${lookup(var.private_subnet, "availability_zone")}"
    cidr_block = "${lookup(var.private_subnet,"cidr_block")}"
    tags = {
    Name = "${lookup(var.private_subnet,"Name")}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}
  

resource "aws_route_table" "IGW-RT" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
   tags = {
    Name = "Public_route"
    }
}

resource "aws_route_table_association" "publicsubnetRT" {
    subnet_id = "${aws_subnet.public_subnet.id}"
    route_table_id = aws_route_table.IGW-RT.id
}


resource "aws_security_group" "allow_tls" {
  name        = var.sgname
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "allow_tls"
  }
}

resource "aws_eip" "Elastic_IP" {
  domain = "vpc"
  }

  resource "aws_nat_gateway" "NAT-GW" {
  allocation_id = "${aws_eip.Elastic_IP.id}"
  subnet_id = "${aws_subnet.public_subnet.id}"

  tags = {
    Name = "NAT-GW"
  }
}

resource "aws_route_table" "NAT-RT" {
    vpc_id = aws_vpc.main.id
    
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.NAT-GW.id}"
    }

    tags = {
    Name = "Private_route"
    }
}

resource "aws_route_table_association" "privatesubnetRT" {
    subnet_id = "${aws_subnet.private_subnet.id}"
    route_table_id = "${aws_route_table.NAT-RT.id}"
}

resource "aws_key_pair" "deployer" {
  key_name   = var.awskeypair
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD7qb+nwL3SFd1AGqMmHv2ba9BbMleZTWT5BBo0jQiRNKi2EG/SfnbbmS2exps0J54DlP6jE6fTDtAcNQ947Ea31BBlUVT2i7czxd2HGZMI+IcEJ+J72X4t3ftLxneJ1ZXDLrQynCRWI87dGMcdeezWuxUT4QOg4UQmuXO5ZxIIJz9odpSeN4mhdRXkhI/w0usu1Ayjwk0xjbHxevIhNaY8Px8oom7W7mnAs7OLFxGKe442F8XHG+yzyoBKAh6fZEMe8++JInbdhC6FHyMC46ZdwRTciPD1HjArMzRMJMe3g760t5AdDPkqLVcqutOqtqxqcavU8DcRp0Yi8TjqBLWxb46UIJUGgt1c8s6/6i/PTEza/0ORCde+c8jGSaYUgmAFe39E0j9Y41s/QDRlx+g34CXfIyaJSSeL4J8Y0JUoLSwj2dMqRBjKPzjsRQ+hpPv4SC4KFZhGsKueBpXIyYHjI9rdZreU6u8bbZEXhGUMfDUcutb6AFq0RQ5PVFYmOKs= ADMIN@DESKTOP-0DPH4JJ"

  }

resource "aws_ebs_volume" "example" {
  availability_zone =var.aws_ebs_volume
  size              = 30

  tags = {
    Name = "HelloWorld"
  }
}


resource "aws_instance" "this" {
  ami                     = lookup(var.aws_instance,"ami")
  instance_type           = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids  = [aws_security_group.allow_tls.id]
  associate_public_ip_address = "1"


  key_name             = aws_key_pair.deployer.id
   tags = {
    Name = "test"
  }
}


resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.example.id
  instance_id = aws_instance.this.id
}

resource "aws_lb" "load-balancer" {
  name = var.aws_lb
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.allow_tls.id]
  subnets = [
    aws_subnet.public_subnet.id,
    aws_subnet.private_subnet.id
  ]

  tags =  {
    Name = "load-balancer"
  }
}


resource "aws_lb_target_group" "alb-tg-group" {
  name        = "alb-tg"
  port        = 80
  protocol    = "HTTP"
  protocol_version = "HTTP1"
  vpc_id      = aws_vpc.main.id

  health_check {
    healthy_threshold = "3"
    interval = "30"
    protocol = "HTTP"
    matcher = "200"
    port = 80
    timeout = "5"
    path = "/."
    unhealthy_threshold = "3"
  }

}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.alb-tg-group.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "health_check" {
  listener_arn = aws_lb_listener.front_end.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg-group.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

}



#resource "aws_launch_configuration" "Launch-Configuration" {
#  name   = lookup(var.aws_launch_configuration,"name")
#  image_id      =lookup(var.aws_instance,"ami")
#  instance_type = lookup(var.aws_instance,"instance_type")
#  security_groups = [aws_security_group.allow_tls.id]
#  associate_public_ip_address = "1"
#  key_name = "Meghana"
#  user_data = file("${path.module}/main.sh")

#  lifecycle {
#    create_before_destroy = true
#  }
#}

resource "aws_launch_template" "template" {
  name = "template"

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
    }
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  disable_api_stop        = true
  disable_api_termination = true

  ebs_optimized = true
  image_id = lookup(var.aws_instance,"ami")
  instance_type = lookup(var.aws_instance,"instance_type")
  key_name = aws_key_pair.deployer.id

  monitoring {
    enabled = true
  }
  vpc_security_group_ids = [aws_security_group.allow_tls.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "devops_practice"
    }
  }
  user_data = filebase64("${path.module}/main.sh")
}


resource "aws_autoscaling_group" "Auto-Scaling-Group" {
  name                 = lookup(var.aws_autoscaling_group,"name")
  #launch_configuration = aws_launch_configuration.Launch-Configuration.name
  vpc_zone_identifier = [aws_subnet.public_subnet.id]
  min_size             = 2
  max_size             = 3

   launch_template {
    id      = aws_launch_template.template.id
    version = aws_launch_template.template.latest_version
  }

    tag {
      key = "name"
      value = lookup(var.aws_autoscaling_group,"name")
      propagate_at_launch = true
    }
  
}


# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.Auto-Scaling-Group.id
  lb_target_group_arn    = aws_lb_target_group.alb-tg-group.arn 
}





