terraform {
  required_providers {
    metal = {
      source  = "equinix/metal"
      version = "3.3.0"
    }

    cloudamqp = {
      source = "cloudamqp/cloudamqp"
    }
  }
}
