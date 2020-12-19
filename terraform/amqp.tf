provider "cloudamqp" {}

resource "cloudamqp_instance" "instance" {
  name          = "ofborg"
  plan          = "squirrel-1"
  region        = "amazon-web-services::us-east-1"
  nodes         = 1
  tags          = concat(var.tags, ["core-0", "skip-hydra"])
   no_default_alarms = true
}

resource "cloudamqp_notification" "graham" {
  instance_id = cloudamqp_instance.instance.id
  type        = "email"
  value       = "graham@grahamc.com"
  name        = "Graham Christensen"
}

resource "cloudamqp_alarm" "notice_alarm" {
  instance_id       = cloudamqp_instance.instance.id
  type              = "notice"
  enabled           = true
  recipients = [ cloudamqp_notification.graham.id ]
}

resource "cloudamqp_alarm" "cpu_alarm_90" {
  instance_id       = cloudamqp_instance.instance.id
  type              = "cpu"
  enabled           = true
  value_threshold   = 90
  time_threshold    = 600
  recipients = [cloudamqp_notification.graham.id]
}

resource "cloudamqp_alarm" "cpu_alarm_95" {
  instance_id       = cloudamqp_instance.instance.id
  type              = "cpu"
  enabled           = true
  value_threshold   = 95
  time_threshold    = 600
  recipients = [cloudamqp_notification.graham.id]
}

resource "cloudamqp_alarm" "memory_alarm_80" {
  instance_id       = cloudamqp_instance.instance.id
  type              = "memory"
  enabled           = true
  value_threshold   = 80
  time_threshold    = 600
  recipients = [cloudamqp_notification.graham.id]
}


resource "cloudamqp_alarm" "memory_alarm_95" {
  instance_id       = cloudamqp_instance.instance.id
  type              = "memory"
  enabled           = true
  value_threshold   = 95
  time_threshold    = 600
  recipients = [cloudamqp_notification.graham.id]
}

