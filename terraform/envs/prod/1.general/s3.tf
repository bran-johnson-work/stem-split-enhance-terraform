module "s3_logs" {
  source = "../../../modules/s3"

  s3_bucket = {
    name             = "${var.project}-${var.env}-logs-s3"
    versioning       = "Enabled"
    object_ownership = "BucketOwnerPreferred"
    lifecycle = [
      {
        id              = "expire-alb-vpc-log"
        status          = "Enabled"
        filter_prefix   = "AWSLogs/"
        expiration_days = 30
      },
      {
        id              = "expire-cf-logs"
        status          = "Enabled"
        filter_prefix   = "cf-logs/"
        expiration_days = 30
      }
    ]
  }

  s3_bucket_policy = {
    template = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Sid" : "AWSLogDeliveryWrite",
            "Effect" : "Allow",
            "Principal" : {
              "Service" : "delivery.logs.amazonaws.com"
            },
            "Action" : "s3:PutObject",
            "Resource" : "arn:aws:s3:::${var.project}-${var.env}-logs-s3/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition" : {
              "StringEquals" : {
                "s3:x-amz-acl" : "bucket-owner-full-control",
                "aws:SourceAccount" : data.aws_caller_identity.current.account_id
              }
            }
          },
          {
            "Sid" : "ALBLogDeliveryWrite",
            "Effect" : "Allow",
            "Principal" : {
              "AWS" : data.aws_elb_service_account.main.arn
            },
            "Action" : "s3:PutObject",
            "Resource" : "arn:aws:s3:::${var.project}-${var.env}-logs-s3/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
          }
        ]
      }
    )
  }
}
