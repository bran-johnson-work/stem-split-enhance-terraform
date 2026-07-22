#modules/s3/_outputs.tf
#s3-bucket
output "s3_bucket_id" {
  value       = aws_s3_bucket.s3_bucket.id
  description = "ID of S3 Bucket"
}
output "s3_bucket_domain_name" {
  value       = aws_s3_bucket.s3_bucket.bucket_domain_name
  description = "Domain name of S3 Bucket"
}
output "s3_bucket_regional_domain_name" {
  value       = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
  description = "Regional domain name of S3 Bucket"
}
output "s3_bucket_arn" {
  value       = aws_s3_bucket.s3_bucket.arn
  description = "ARN of S3 Bucket"
}

#s3-object
output "s3_object_key" {
  value       = { for key, value in aws_s3_object.s3_object : key => value.id }
  description = "Map of keys and IDs of S3 objects"
}
