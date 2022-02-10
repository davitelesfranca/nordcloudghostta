resource "aws_s3_bucket" "observability_bucket_nginx" {
  bucket_prefix = "ob-ghost-nginx-nordcloud-"
  acl           = "private"

  tags = {
    Name = "Observability Nginx NordCloud"
  }
}

resource "aws_s3_bucket" "observability_bucket_ghost" {
  bucket_prefix = "ob-ghost-app-nordcloud-"
  acl           = "private"

  tags = {
    Name = "Observability NordCloud"
  }
}

resource "aws_s3_bucket_object" "script_file" {
  bucket = aws_s3_bucket.observability_bucket_ghost.id
  key    = "nordcloud_ghost_init.sh"
  source = "./user_data/nordcloud_ghost_init.sh"

  etag = filemd5("/home/dfranca-dev/aws-ghost-deployment-main/terraform/user_data/nordcloud_ghost_init.sh")
}
