resource "aws_s3_bucket" "observability_bucket_nginx" {
  bucket = "ob-nginx-ghost-nordcloud"
  acl    = "private"

  tags = {
    Name        = "Observability Nginx NordCloud"
  }
}

resource "aws_s3_bucket" "observability_bucket_ghost" {
  bucket = "ob-nginx-app-nordcloud"
  acl    = "private"

  tags = {
    Name        = "Observability NordCloud"
  }
}
