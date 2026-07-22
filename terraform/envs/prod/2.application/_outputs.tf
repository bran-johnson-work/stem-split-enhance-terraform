output "aurora_cluster_endpoint" {
  value = module.aurora.cluster_endpoint
}
output "app_public_ip" {
  value       = module.ec2_app.public_ip
  description = "Stable public IP of the app host (frontend + backend)."
}
