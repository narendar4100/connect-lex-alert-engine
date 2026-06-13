resource "aws_s3_bucket" "this" {
  bucket = var.name
  acl    = "private"
  versioning {
    enabled = var.versioning
  }
  tags = merge(var.tags, {
    Name = var.name
  })
}
data "aws_region" "current" {}
output "bucket_id" {
  value = aws_s3_bucket.this.bucket
}
