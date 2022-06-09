terraform {
  required_providers {
    metal = {
      source  = "equinix/metal"
      version = "3.3.0-alpha.3"
    }

    cloudamqp = {
      source = "cloudamqp/cloudamqp"
    }
  }
}
