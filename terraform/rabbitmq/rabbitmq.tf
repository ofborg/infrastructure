# As root:
#
# RABBITMQ_USE_LONGNAME=true HOME=/var/lib/rabbitmq rabbitmqctl add_user terraform-admin thepassword
# RABBITMQ_USE_LONGNAME=true HOME=/var/lib/rabbitmq rabbitmqctl set_user_tags terraform-admin administrator management
# RABBITMQ_USE_LONGNAME=true HOME=/var/lib/rabbitmq rabbitmqctl delete_user guest
#
# Locally:
# nixops ssh core-0 -L 15672:localhost:15672
# and rabbitmq_management_endpoint = "http://127.0.0.1:15672/"

variable "monitoring_user" {
  type = object({
    name = string
    password = string
  })
}

variable "webhook_user" {
  type = object({
    name = string
    password = string
  })
}

variable "ofborgservice_user" {
  type = object({
    name = string
    password = string
  })
}
 

variable "logviewer_user" {
  type = object({
    name = string
    password = string
  })
}
 
variable "builders" {
  type = map(object({
    password = string
  }))
}

# Configure the RabbitMQ provider
provider "rabbitmq" {
  endpoint = data.terraform_remote_state.base.outputs.rabbitmq_management_endpoint
  username = data.terraform_remote_state.base.outputs.rabbitmq_username
  password = data.terraform_remote_state.base.outputs.rabbitmq_password
}

resource "rabbitmq_vhost" "ofborg" {
  name = "ofborg"
}

resource "rabbitmq_user" "monitoring" {
  name     = var.monitoring_user.name
  password = var.monitoring_user.password
  tags     = [ "monitoring" ]
}
 
resource "rabbitmq_permissions" "monitoring-access" {
  user  = rabbitmq_user.monitoring.name
  vhost = rabbitmq_vhost.ofborg.name

  permissions {
    configure = "^$"
    write     = "^$"
    read      = "^$"
  }
}
 
resource "rabbitmq_permissions" "monitoring-access-root" {
  user  = rabbitmq_user.monitoring.name
  vhost = "/"

  permissions {
    configure = "^$"
    write     = "^$"
    read      = "^$"
  }
}
 
resource "rabbitmq_user" "ofborgservice" {
  name     = var.ofborgservice_user.name
  password = var.ofborgservice_user.password
  tags     = [ ]
}

resource "rabbitmq_permissions" "ofborgservice-access" {
  user  = rabbitmq_user.ofborgservice.name
  vhost = rabbitmq_vhost.ofborg.name

  permissions {
    configure = ".*"
    write     = ".*"
    read      = ".*"
  }
}

resource "rabbitmq_user" "logviewer" {
  name     = var.logviewer_user.name
  password = var.logviewer_user.password
  tags     = [ ]
}

resource "rabbitmq_permissions" "logviewer-access" {
  user  = rabbitmq_user.logviewer.name
  vhost = rabbitmq_vhost.ofborg.name

  permissions {
    configure = "^(stomp-subscription-.*)"
    write     = "^(stomp-subscription-.*)"
    read      = "^(stomp-subscription-.*|logs)"
  }
}

resource "rabbitmq_user" "builders" {
  for_each = var.builders
  name     = "builder-${each.key}"
  password = each.value.password
  tags     = [ ]
}

resource "rabbitmq_permissions" "builders" {
  for_each = var.builders
  user  = "builder-${each.key}"
  vhost = rabbitmq_vhost.ofborg.name

  permissions {
    configure = ".*"
    write     = ".*"
    read      = ".*"
  }
}

resource "rabbitmq_user" "webhook" {
  name     = var.webhook_user.name
  password = var.webhook_user.password
  tags     = [ ]
}

resource "rabbitmq_permissions" "webhook-access" {
  user  = rabbitmq_user.webhook.name
  vhost = rabbitmq_vhost.ofborg.name

  permissions {
    configure = "^(github-events|github-events-unknown)$"
    write     = "^(github-events|github-events-unknown)$"
    read      = "^(github-events)$"
  }
}

