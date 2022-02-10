#Prints the dns name for the AELB that points to Ghost application
output "aelb_address" {
  value = aws_lb.nordcloud_aelb.dns_name
}

output "bucket_s3_object" {
  value = aws_s3_bucket_object.script_file.id
}

output "nginx_bucket" {
  value = aws_s3_bucket.observability_bucket_nginx.id
}

output "ghost_bucket" {
  value = aws_s3_bucket.observability_bucket_ghost.id
}
