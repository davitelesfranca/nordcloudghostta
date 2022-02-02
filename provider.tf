terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0" # Allows only the rightmost version component to increment
    }

    random = {
      source = "hashicorp/random"
    }
  }

  cloud {
    organization = "davitelesfranca"

    workspaces {
      name = "nordcloudghostta"
    }
  }
}

provider "aws" {
  region = var.region
}
