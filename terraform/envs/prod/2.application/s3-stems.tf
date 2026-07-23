module "s3_stems" {
  source = "../../../modules/s3"

  s3_bucket = {
    name       = "${var.project}-${var.env}-stems"
    versioning = "Enabled"

    cors_rule = [
      {
        allowed_headers = ["*"]
        allowed_methods = ["GET", "HEAD", "PUT", "POST"]
        allowed_origins = ["https://${var.domain_name}", "http://localhost:3000"]
        expose_headers  = ["ETag"]
        max_age_seconds = 3600
      }
    ]
  }
}
