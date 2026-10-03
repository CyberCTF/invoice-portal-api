output "instance_id" {
  value = aws_instance.labhost.id
}

output "ip" {
  value = aws_instance.labhost.public_ip
}
