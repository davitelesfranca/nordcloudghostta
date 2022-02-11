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

output "elk_endpoint" {
  value = aws_elasticsearch_domain.nordcloud-es.endpoint
}

output "elk_kibana_endpoint" {
  value = aws_elasticsearch_domain.nordcloud-es.kibana_endpoint
}
