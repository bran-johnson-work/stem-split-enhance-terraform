# IAM user for the off-AWS GPU worker (e.g. vast.ai). A rented box has no instance
# profile / IMDS, so it needs static access keys for S3. Same S3 permissions as the
# in-VPC worker role: read inputs from media, write stems to stems. The DB is reached
# separately via an SSH tunnel through the app host, so no DB access lives here.
#
# NOTE: create the access key manually (console: IAM > Users > this user > Security
# credentials > Create access key, or `aws iam create-access-key --user-name <name>`)
# and put AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY in the worker host's .env.
module "iam_user_worker" {
  source = "../../../modules/iam-user"

  env     = var.env
  project = var.project
  name    = "ext-worker"

  iam_custom_policy = {
    template = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "S3BucketLevel",
          "Effect" : "Allow",
          "Action" : [
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads"
          ],
          "Resource" : [
            module.s3_media.s3_bucket_arn,
            module.s3_stems.s3_bucket_arn
          ]
        },
        {
          "Sid" : "S3ObjectLevel",
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:AbortMultipartUpload",
            "s3:ListMultipartUploadParts"
          ],
          "Resource" : [
            "${module.s3_media.s3_bucket_arn}/*",
            "${module.s3_stems.s3_bucket_arn}/*"
          ]
        }
      ]
    })
  }
}

output "ext_worker_iam_user_name" {
  value       = module.iam_user_worker.iam_user_name
  description = "IAM user for the off-AWS worker — create an access key for this user."
}
