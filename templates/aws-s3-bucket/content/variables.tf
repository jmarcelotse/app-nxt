variable "region" {
  description = "AWS region"
  type        = string
  default     = "${{ values.region }}"
}

variable "bucket_name" {
  description = "Nome do bucket S3"
  type        = string
  default     = "${{ values.name }}"
}

variable "tags" {
  description = "Tags do recurso"
  type        = map(string)
  default = {
    ManagedBy   = "terraform"
    Environment = "staging"
    Owner       = "${{ values.owner }}"
    CreatedBy   = "backstage"
  }
}
