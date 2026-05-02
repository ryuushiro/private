variable "aws_region" {
  description = "AWS region"
  default     = "ap-southeast-3"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  default     = "~/.ssh/id_rsa_final_task.pub"
}

/*
variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for studentdumbways.my.id"
  type        = string
}

variable "student_name" {
  description = "Student name for subdomains"
  default     = "rizal"
}
*/
