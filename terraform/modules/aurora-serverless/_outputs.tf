output "cluster_endpoint" {
  description = "Writer endpoint for the cluster"
  value       = aws_rds_cluster.aurora.endpoint
}
output "cluster_reader_endpoint" {
  description = "Reader endpoint for the cluster"
  value       = aws_rds_cluster.aurora.reader_endpoint
}
output "cluster_id" {
  description = "The RDS Cluster Identifier"
  value       = aws_rds_cluster.aurora.id
}
output "cluster_arn" {
  description = "The ARN of the RDS Cluster"
  value       = aws_rds_cluster.aurora.arn
}
output "cluster_port" {
  description = "The port of the cluster"
  value       = aws_rds_cluster.aurora.port
}
