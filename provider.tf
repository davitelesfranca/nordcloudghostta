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

  #To allow Github Actions be able to runs it on Hashicorp cloud environment, 
  # we need to define a organization and a workspace's organization
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