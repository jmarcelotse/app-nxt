variable "region" {
  type    = string
  default = "${{ values.region }}"
}

variable "name" {
  type    = string
  default = "${{ values.name }}"
}

variable "environment" {
  type    = string
  default = "${{ values.environment }}"
}

variable "instance_type" {
  type    = string
  default = "${{ values.instanceType }}"
}

variable "instance_count" {
  type    = number
  default = ${{ values.instanceCount }}
}

variable "use_spot" {
  type    = bool
  default = ${{ values.useSpot }}
}

variable "db_engine" {
  type    = string
  default = "${{ values.dbEngine }}"
}

variable "db_instance_class" {
  type    = string
  default = "${{ values.dbInstanceClass }}"
}

variable "db_storage" {
  type    = number
  default = ${{ values.dbStorage }}
}

variable "db_multi_az" {
  type    = bool
  default = ${{ values.dbMultiAz }}
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "domain" {
  type    = string
  default = "${{ values.domain }}"
}

variable "subdomain" {
  type    = string
  default = "${{ values.subdomain }}"
}

variable "cloudflare_zone_id" {
  type    = string
  default = "${{ values.cloudflareZoneId }}"
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "${{ values.name }}"
    ManagedBy   = "terraform"
    Environment = "${{ values.environment }}"
    Owner       = "${{ values.owner }}"
    CreatedBy   = "backstage"
  }
}
