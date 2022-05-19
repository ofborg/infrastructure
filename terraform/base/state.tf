terraform {
  backend "s3" {
    bucket = "grahamc-nixops-state"
    key = "ofborg-terraform"
    region = "us-east-1"
    kms_key_id = "166c5cbe-b827-4105-bdf4-a2db9b52efb4"
  }

  required_providers {
    metal = {
      source = "equinix/metal"
      version = "3.3.0-alpha.3"
    }

    cloudamqp = {
      source = "cloudamqp/cloudamqp"
    }
  }
}

variable "tags" {
  type    = list(string)
  default = ["terraform-ofborg"]
}
