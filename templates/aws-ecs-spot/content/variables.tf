variable "region" {
  type    = string
  default = "${{ values.region }}"
}

variable "name" {
  type    = string
  default = "${{ values.name }}"
}

variable "container_image" {
  type    = string
  default = "${{ values.containerImage }}"
}

variable "container_port" {
  type    = number
  default = ${{ values.containerPort }}
}

variable "cpu" {
  type    = string
  default = "${{ values.cpu }}"
}

variable "memory" {
  type    = string
  default = "${{ values.memory }}"
}

variable "desired_count" {
  type    = number
  default = ${{ values.desiredCount }}
}

variable "spot_percentage" {
  type    = number
  default = ${{ values.spotPercentage }}
}

variable "tags" {
  type = map(string)
  default = {
    ManagedBy   = "terraform"
    Environment = "staging"
    Owner       = "${{ values.owner }}"
    CreatedBy   = "backstage"
  }
}
