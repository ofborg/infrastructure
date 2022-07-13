terraform {
  backend "s3" {
    bucket         = "ofborg-ofborg-state20220613164850806600000002"
    dynamodb_table = "ofborg-ofborg-state"
    encrypt        = true
    key            = "ofborg-terraform-rabbitmq"
    kms_key_id     = "eebecfff-057c-4202-b8b2-5603f07c618e"
    region         = "us-east-2"
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
    bucket         = "ofborg-ofborg-state20220613164850806600000002"
    dynamodb_table = "ofborg-ofborg-state"
    encrypt        = true
    key            = "ofborg-terraform"
    kms_key_id     = "eebecfff-057c-4202-b8b2-5603f07c618e"
    region         = "us-east-2"
  }
}

variable "tags" {
  type    = list(string)
  default = ["terraform-ofborg"]
}

