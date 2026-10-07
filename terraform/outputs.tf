output "ec2_public_ip" {
  description = "Public IP address of the NestJS EC2 instance"
  value       = aws_instance.nestjs_ec2.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.nestjs_ec2.id
}

output "vpc_id" {
  description = "Existing VPC ID"
  value       = data.aws_vpc.existing_vpc.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.nestjs_ec2_security_group.id
}
