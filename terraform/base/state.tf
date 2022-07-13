terraform {
  backend "s3" {
    bucket         = "ofborg-ofborg-state20220613164850806600000002"
    dynamodb_table = "ofborg-ofborg-state"
    encrypt        = true
    key            = "ofborg-terraform"
    kms_key_id     = "eebecfff-057c-4202-b8b2-5603f07c618e"
    region         = "us-east-2"
  }
}
