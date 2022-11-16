# main.tf | Main Configuration

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  # backend "s3" {
  #   bucket = "terraform-state-bucket"
  #   key    = "state/terraform_state.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}
