output "aelb_address" {
  value = aws_lb.nordcloud_aelb.dns_name
}
