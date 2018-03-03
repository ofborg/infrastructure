# As root:
#
# RABBITMQ_USE_LONGNAME=true HOME=/var/lib/rabbitmq rabbitmqctl add_user terraform-admin thepassword
# RABBITMQ_USE_LONGNAME=true HOME=/var/lib/rabbitmq rabbitmqctl set_user_tags terraform-admin administrator management
# RABBITMQ_USE_LONGNAME=true HOME=/var/lib/rabbitmq rabbitmqctl delete_user guest
#
# Locally:
# nixops ssh core-0 -L 15672:localhost:15672
# and rabbitmq_management_endpoint = "http://127.0.0.1:15672/"

variable "rabbitmq_management_endpoint" {
  type = "string"
}

variable "rabbitmq_management_username" {
  type = "string"
}

variable "rabbitmq_management_password" {
  type = "string"
}

variable "rabbitmq_monitoring_username" {
  type = "string"
}

variable "rabbitmq_monitoring_password" {
  type = "string"
}

variable "rabbitmq_webhook_username" {
  type = "string"
}

variable "rabbitmq_webhook_password" {
  type = "string"
}

variable "rabbitmq_ofborgservice_username" {
  type = "string"
}

variable "rabbitmq_ofborgservice_password" {
  type = "string"
}


# Configure the RabbitMQ provider
provider "rabbitmq" {
  endpoint = "${var.rabbitmq_management_endpoint}"
  username = "${var.rabbitmq_management_username}"
  password = "${var.rabbitmq_management_password}"
}

resource "rabbitmq_user" "terraform" {
  name     = "${var.rabbitmq_management_username}"
  password = "${var.rabbitmq_management_password}"
  tags     = ["administrator", "management"]
}

resource "rabbitmq_permissions" "terraform-access" {
  user  = "${rabbitmq_user.terraform.name}"
  vhost = "${rabbitmq_vhost.ofborg.name}"

  permissions {
    configure = ".*"
    write     = ".*"
    read      = ".*"
  }
}

resource "rabbitmq_user" "monitoring" {
  name     = "${var.rabbitmq_monitoring_username}"
  password = "${var.rabbitmq_monitoring_password}"
  tags     = [ "management"]
}

resource "rabbitmq_user" "ofborgservice" {
  name     = "${var.rabbitmq_ofborgservice_username}"
  password = "${var.rabbitmq_ofborgservice_password}"
  tags     = [ ]
}

resource "rabbitmq_permissions" "ofborgservice-access" {
  user  = "${rabbitmq_user.ofborgservice.name}"
  vhost = "${rabbitmq_vhost.ofborg.name}"

  permissions {
    configure = ".*"
    write     = ".*"
    read      = ".*"
  }
}

resource "rabbitmq_user" "webhook" {
  name     = "${var.rabbitmq_webhook_username}"
  password = "${var.rabbitmq_webhook_password}"
  tags     = [ ]
}

resource "rabbitmq_permissions" "webhook-access" {
  user  = "${rabbitmq_user.webhook.name}"
  vhost = "${rabbitmq_vhost.ofborg.name}"

  permissions {
    configure = "^(github-events|github-events-unknown)$"
    write     = "^(github-events|github-events-unknown)$"
    read      = "^(github-events)$"
  }
}

# Create a virtual host
resource "rabbitmq_vhost" "ofborg" {
  name = "ofborg"
}
