terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "backstage-terraform-state-897729098910"
    key    = "${{ values.name }}/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}
