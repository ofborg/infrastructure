terraform {
  backend "s3" {
    bucket  = "nixos-terraform-state"
    encrypt = true
    key     = "targets/ofborg/base"
    region  = "eu-west-1"
    profile = "nixos-prod"
  }
}
