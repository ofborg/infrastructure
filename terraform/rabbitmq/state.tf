terraform {
  backend "s3" {
    bucket  = "nixos-terraform-state"
    encrypt = true
    key     = "targets/ofborg/rabbitmq"
    region  = "eu-west-1"
    profile = "nixos-prod"
  }

  required_providers {
    rabbitmq = {
      source = "cyrilgdn/rabbitmq"
    }
  }
}

data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket  = "nixos-terraform-state"
    encrypt = true
    key     = "targets/ofborg/base"
    region  = "eu-west-1"
    profile = "nixos-prod"
  }
}

variable "tags" {
  type    = list(string)
  default = ["terraform-ofborg"]
}

