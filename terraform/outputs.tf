output "ec2_public_ip" {
  description = "Public IP address of the NestJS EC2 instance"
  value       = aws_instance.nestjs_instance.public_ip
}
