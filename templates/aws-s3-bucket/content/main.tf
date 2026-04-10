terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure o backend conforme seu ambiente
    # bucket = "terraform-state-bucket"
    # key    = "${{ values.name }}/terraform.tfstate"
    # region = "${{ values.region }}"
    # profile = "staging"
  }
}

provider "aws" {
  region  = var.region
  profile = "staging"
}
