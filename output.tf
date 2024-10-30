output "vpc_id" {
    value = aws_vpc.main.id
}


output "public_subnet" {
    value = aws_subnet.public_subnet.id
}

output "private_subnet" {
    value = aws_subnet.private_subnet.id
}

output "igw" {
    value = aws_internet_gateway.gw.id
}

output "nat" {
    value = aws_nat_gateway.NAT-GW.id
}

output "alb_id" {
    value = aws_lb.load-balancer.id
}

output "alb_dnsname" {
    value = aws_lb.load-balancer.dns_name
}

#output "aws_launch_configuration" {
#   value = aws_launch_configuration.Launch-Configuration.id
#}

output "aws_launch_template" {
    value = aws_launch_template.template.tags_all 
}