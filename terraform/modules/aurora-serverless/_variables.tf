variable "env" {
  description = "Name of project environment"
  type        = string
}
variable "project" {
  description = "Name of project"
  type        = string
}
variable "name" {
  description = "Name identifier for Aurora resources"
  type        = string
}
variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
}
variable "parameter_group_family" {
  description = "Parameter group family (e.g. aurora-postgresql16)"
  type        = string
}
variable "database_name" {
  description = "Name of the default database"
  type        = string
}
variable "master_username" {
  description = "Master username for the cluster"
  type        = string
}
variable "master_password" {
  description = "Master password for the cluster"
  type        = string
  sensitive   = true
}
variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}
variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}
variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}
variable "kms_key_id" {
  description = "ARN of the KMS key for encryption"
  type        = string
}
variable "instance_count" {
  description = "Number of Aurora instances"
  type        = number
  default     = 1
}
variable "min_capacity" {
  description = "Minimum ACU capacity for serverless v2"
  type        = number
  default     = 0.5
}
variable "max_capacity" {
  description = "Maximum ACU capacity for serverless v2"
  type        = number
  default     = 4
}
variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}
variable "preferred_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "17:00-17:30"
}
variable "preferred_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:16:00-sun:17:00"
}
variable "parameters" {
  description = "List of cluster parameter group parameters"
  type = list(object({
    name         = string
    value        = string
    apply_method = string
  }))
  default = []
}
