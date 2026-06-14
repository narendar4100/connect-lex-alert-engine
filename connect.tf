resource "aws_connect_instance" "connect" {
  identity_management_type = "CONNECT_MANAGED"
  inbound_calls_enabled    = true
  outbound_calls_enabled   = true
  instance_alias           = "developer-alert-${var.environment}-connect"
}

resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-alerts"
}

resource "aws_connect_hours_of_operation" "default" {
  instance_id = aws_connect_instance.connect.id
  name        = "${var.environment}-24x7"
  time_zone   = "UTC"

  config {
    day = "MONDAY"
    start_time {
      hours   = 0
      minutes = 0
    }
    end_time {
      hours   = 23
      minutes = 59
    }
  }
  config {
    day = "TUESDAY"
    start_time {
      hours   = 0
      minutes = 0
    }
    end_time {
      hours   = 23
      minutes = 59
    }
  }
  config {
    day = "WEDNESDAY"
    start_time {
      hours   = 0
      minutes = 0
    }
    end_time {
      hours   = 23
      minutes = 59
    }
  }
  config {
    day = "THURSDAY"
    start_time {
      hours   = 0
      minutes = 0
    }
    end_time {
      hours   = 23
      minutes = 59
    }
  }
  config {
    day = "FRIDAY"
    start_time {
      hours   = 0
      minutes = 0
    }
    end_time {
      hours   = 23
      minutes = 59
    }
  }
  config {
    day = "SATURDAY"
    start_time {
      hours   = 0
      minutes = 0
    }
    end_time {
      hours   = 23
      minutes = 59
    }
  }
  config {
    day = "SUNDAY"
    start_time {
      hours   = 0
      minutes = 0
    }
    end_time {
      hours   = 23
      minutes = 59
    }
  }
}

resource "aws_connect_queue" "default" {
  name                  = "${var.environment}-default-queue"
  instance_id           = aws_connect_instance.connect.id
  # FIXED: Switched to hours_of_operation_id attribute path
  hours_of_operation_id = aws_connect_hours_of_operation.default.hours_of_operation_id 
}


resource "aws_connect_routing_profile" "default" {
  instance_id               = aws_connect_instance.connect.id
  name                      = "${var.environment}-routing-profile"
  description               = "Default routing profile for ${var.environment}"
  
  # FIXED: Switched from .id to .queue_id attribute path
  default_outbound_queue_id = aws_connect_queue.default.queue_id

  media_concurrencies {
    channel     = "VOICE"
    concurrency = 1
  }

  queue_configs {
    channel  = "VOICE"
    # FIXED: Switched from .id to .queue_id here as well
    queue_id = aws_connect_queue.default.queue_id
    delay    = 0
    priority = 1
  }
}

resource "aws_connect_security_profile" "default" {
  instance_id = aws_connect_instance.connect.id
  name        = "${var.environment}-security-profile"
}

resource "aws_connect_user" "admin" {
  instance_id        = aws_connect_instance.connect.id
  name               = "Admin User"
  password           = var.admin_password
  routing_profile_id = aws_connect_routing_profile.default.id
  security_profile_ids = [
    aws_connect_security_profile.default.id
  ]
  phone_config {
    phone_type = "SOFT_PHONE"
  }
}

resource "local_file" "contact_flow_generated" {
  filename        = "${path.module}/connect/contact_flow.generated.json"
  file_permission = "0644"
  content = templatefile(
    "${path.module}/connect/contact_flow.tpl",
    {
      lambda_arn          = module.lambda_incident.function_arn,
      connect_instance_id = aws_connect_instance.connect.id,
      phone_number        = aws_connect_phone_number.claim.phone_number
    }
  )
}

resource "aws_connect_contact_flow" "incident_flow" {
  instance_id = aws_connect_instance.connect.id
  name        = "${var.environment}-incident-flow"
  content     = local_file.contact_flow_generated.content
}

resource "aws_connect_phone_number" "claim" {
  country_code = var.claim_country_code
  target_arn   = aws_connect_instance.connect.arn
  type         = "DID"
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
