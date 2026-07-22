module "s3_media" {
  source = "../../../modules/s3"

  s3_bucket = {
    name       = "${var.project}-${var.env}-media"
    versioning = "Enabled"
    cors_rule = [
      {
        allowed_headers = ["*"]
        allowed_methods = ["GET", "HEAD", "PUT", "POST"]
        allowed_origins = ["https://${var.domain_name}"]
        expose_headers  = ["ETag"]
        max_age_seconds = 3600
      }
    ]
  }
  # Media is served to the browser via short-lived presigned S3 URLs (the app signs
  # them with its instance-role creds), so no bucket policy is needed. Access is
  # governed by the app/worker IAM role; the public-access-block stays fully on.
}
