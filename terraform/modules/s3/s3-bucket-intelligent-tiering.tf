resource "aws_s3_bucket_intelligent_tiering_configuration" "entire_bucket" {
  count = var.s3_bucket.intelligent_tiering ? 1 : 0

  bucket = aws_s3_bucket.s3_bucket.id
  name   = "EntireBucket"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 125
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}
