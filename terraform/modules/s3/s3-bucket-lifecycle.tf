resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle" {
  count = (var.s3_bucket.lifecycle_versioning != null || length(var.s3_bucket.lifecycle) > 0) ? 1 : 0

  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.s3_bucket_versioning]

  bucket = aws_s3_bucket.s3_bucket.id

  dynamic "rule" {
    for_each = (var.s3_bucket.lifecycle_versioning != null && var.s3_bucket.versioning == "Enabled") ? [1] : []
    content {
      id     = "s3-bucket-lifecycle-versioning"
      status = var.s3_bucket.lifecycle_versioning.status

      dynamic "filter" {
        for_each = var.s3_bucket.lifecycle_versioning.filter_prefix != null ? [1] : []
        content {
          prefix = var.s3_bucket.lifecycle_versioning.filter_prefix
        }
      }

      noncurrent_version_expiration {
        noncurrent_days = var.s3_bucket.lifecycle_versioning.noncurrent_version_expiration_days
      }

      dynamic "noncurrent_version_transition" {
        for_each = var.s3_bucket.lifecycle_versioning.noncurrent_version_transition_days_standard_ia != null ? [1] : []
        content {
          noncurrent_days = var.s3_bucket.lifecycle_versioning.noncurrent_version_transition_days_standard_ia
          storage_class   = "STANDARD_IA"
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = var.s3_bucket.lifecycle_versioning.noncurrent_version_transition_days_glacier != null ? [1] : []
        content {
          noncurrent_days = var.s3_bucket.lifecycle_versioning.noncurrent_version_transition_days_glacier
          storage_class   = "GLACIER"
        }
      }
    }
  }

  dynamic "rule" {
    for_each = var.s3_bucket.lifecycle
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "filter" {
        for_each = rule.value.filter_prefix != null ? [1] : []
        content {
          prefix = rule.value.filter_prefix
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_date != null ? [1] : []
        content {
          date = rule.value.expiration_date
        }
      }

      dynamic "transition" {
        for_each = rule.value.transition_days_standard_ia != null ? [1] : []
        content {
          days          = rule.value.transition_days_standard_ia
          storage_class = "STANDARD_IA"
        }
      }

      dynamic "transition" {
        for_each = rule.value.transition_days_glacier != null ? [1] : []
        content {
          days          = rule.value.transition_days_glacier
          storage_class = "GLACIER"
        }
      }
    }
  }
}
