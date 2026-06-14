resource "aws_connect_instance" "connect" {
  identity_management_type = "CONNECT_MANAGED"
  inbound_calls_enabled = true
  outbound_calls_enabled = true
  instance_alias = "${var.environment}-connect"
}

resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-alerts"
}

resource "aws_connect_queue" "default" {
  name = "${var.environment}-default-queue"
  instance_id = aws_connect_instance.connect.id
}

resource "aws_connect_routing_profile" "default" {
  instance_id = aws_connect_instance.connect.id
  name = "${var.environment}-routing-profile"
  default_outbound_queue_id = aws_connect_queue.default.id
  queue_configs = [
    {
      queue_id = aws_connect_queue.default.id
      delay = 0
      priority = 1
    }
  ]
}

resource "aws_connect_security_profile" "default" {
  instance_id = aws_connect_instance.connect.id
  name = "${var.environment}-security-profile"
}

resource "aws_connect_user" "admin" {
  instance_id = aws_connect_instance.connect.id
  name = "Admin User"
  password = var.admin_password
  routing_profile_id = aws_connect_routing_profile.default.id
  security_profile_ids = [aws_connect_security_profile.default.id]
  phone_config {
    phone_type = "SOFT_PHONE"
  }
}

resource "aws_connect_contact_flow" "incident_flow" {
  instance_id = aws_connect_instance.connect.id
  name = "${var.environment}-incident-flow"
  content = file("${path.module}/connect/contact_flow.generated.json")
}

resource "local_file" "contact_flow_generated" {
  filename = "${path.module}/connect/contact_flow.generated.json"
  content  = templatefile(
    "${path.module}/connect/contact_flow.tpl",
    {
      lambda_arn = module.lambda_incident.function_arn,
      connect_instance_id = aws_connect_instance.connect.id,
      phone_number = aws_connect_phone_number.claim.phone_number
    }
  )
  file_permission = "0644"
}

resource "aws_connect_phone_number" "claim" {
  country_code = var.claim_country_code
  target_arn = aws_connect_instance.connect.arn
  type = "DID"
}

resource "aws_connect_bot_association" "lex_association" {
  instance_id = aws_connect_instance.connect.id
  lex_v2_bot_alias_arn = var.lex_v2_bot_alias_arn
  name = "IncidentBotAssociation"
}

output "connect_instance_id" {
  value = aws_connect_instance.connect.id
}

output "connect_admin_user_id" {
  value = aws_connect_user.admin.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}
