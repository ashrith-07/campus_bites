variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "campus-bites"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

# Backend secrets - passed via -var flags from GitHub Actions secrets
variable "database_url" {
  description = "MySQL connection string for Prisma"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT signing secret"
  type        = string
  sensitive   = true
}

variable "cloudinary_cloud_name" {
  description = "Cloudinary cloud name"
  type        = string
  sensitive   = true
}

variable "cloudinary_api_key" {
  description = "Cloudinary API key"
  type        = string
  sensitive   = true
}

variable "cloudinary_api_secret" {
  description = "Cloudinary API secret"
  type        = string
  sensitive   = true
}

variable "pusher_app_id" {
  description = "Pusher App ID"
  type        = string
  sensitive   = true
}

variable "pusher_key" {
  description = "Pusher Key"
  type        = string
  sensitive   = true
}

variable "pusher_secret" {
  description = "Pusher Secret"
  type        = string
  sensitive   = true
}

variable "pusher_cluster" {
  description = "Pusher Cluster"
  type        = string
  default     = "ap2"
}
