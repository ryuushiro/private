output "gateway_public_ip" {
  value = aws_eip.gateway_eip.public_ip
}

output "appserver_1_public_ip" {
  value = aws_eip.appserver_1_eip.public_ip
}

output "appserver_2_public_ip" {
  value = aws_eip.appserver_2_eip.public_ip
}

output "appserver_3_public_ip" {
  value = aws_eip.appserver_3_eip.public_ip
}
