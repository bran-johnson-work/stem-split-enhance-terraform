#S3 Bucket policy
resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  count = var.s3_bucket_policy != null ? 1 : 0

  bucket = aws_s3_bucket.s3_bucket.id
  policy = var.s3_bucket_policy.template
}
