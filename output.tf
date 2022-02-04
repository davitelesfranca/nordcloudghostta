#Prints the dns name for the AELB that points to Ghost application
output "aelb_address" {
  value = aws_lb.nordcloud_aelb.dns_name
}
