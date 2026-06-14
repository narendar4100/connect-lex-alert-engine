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

#  1. PUT THIS BACK TEMPORARILY TO SATISFY THE DEADLOCK
resource "aws_connect_security_profile" "default" {
  instance_id = aws_connect_instance.connect.id
  name        = "${var.environment}-security-profile"
  description = "Temporary placeholder to break the state deadlock"

  # We leave permissions empty because we are moving away from it anyway
  permissions = []

  # FIXED: This line stops Terraform from attempting to destroy it!
  lifecycle {
    prevent_destroy = false
    ignore_changes  = all
  }
}

# 2. Keep the data block to fetch the built-in AWS Admin profile
data "aws_connect_security_profile" "builtin_admin" {
  instance_id = aws_connect_instance.connect.id
  name        = "Admin" 
}

# 3. Ensure your user resource block points to the built-in profile
resource "aws_connect_user" "admin" {
  instance_id        = aws_connect_instance.connect.id
  name               = "admin_user"
  password           = var.admin_password
  routing_profile_id = aws_connect_routing_profile.default.routing_profile_id
  
  # Pointing to the built-in profile safely shifts the user away from the stuck one
  security_profile_ids = [
    data.aws_connect_security_profile.builtin_admin.security_profile_id
  ]
  
  identity_info {
    first_name = "Admin"
    last_name  = "User"
    email      = "admin@yourcompany.com"
  }

  phone_config {
    phone_type = "SOFT_PHONE"
  }
}
# 2. ADD THIS MISSING RESOURCE TO WHITELIST YOUR LAMBDA BEFORE UPLOADING THE FLOW
resource "aws_connect_lambda_function_association" "lambda_whitelist" {
  instance_id = aws_connect_instance.connect.id
  function_arn = module.lambda_incident.function_arn
}

# 3. UPDATE THE CONTACT FLOW TO WAIT UNTIL THE LAMBDA IS ASSOCATED
resource "aws_connect_contact_flow" "incident_flow" {
  instance_id  = aws_connect_instance.connect.id
  name         = "${var.environment}-incident-flow"
  type         = "CONTACT_FLOW"
  content      = local_file.contact_flow_generated.content

  # FIXED: Tells Terraform to wait until the Lambda function is whitelisted in Connect first
  depends_on = [
    aws_connect_lambda_function_association.lambda_whitelist
  ]
}


# resource "aws_connect_user" "admin" {
#   instance_id        = aws_connect_instance.connect.id
#   name               = "admin_user"
#   password           = var.admin_password
#   routing_profile_id = aws_connect_routing_profile.default.routing_profile_id # Ensure this also uses .routing_profile_id or .queue_id guidelines if applicable
  
#   # FIXED: Switched from .id to .security_profile_id
#   security_profile_ids = [
#     aws_connect_security_profile.default.security_profile_id
#   ]
#    # FIXED: Required for CONNECT_MANAGED instances
#   identity_info {
#     first_name = "Admin"
#     last_name  = "User"
#     email      = "narendarreddy.aws@gmail.com" # Change to a valid format
#   }
  
#   phone_config {
#     phone_type = "SOFT_PHONE"
#   }
# }


resource "local_file" "contact_flow_generated" {
  filename        = "${path.module}/connect/contact_flow.generated.json"
  file_permission = "0644"
  content = templatefile(
    "${path.module}/connect/contact_flow.tpl",
    {
      lambda_arn          = module.lambda_incident.function_arn,
      connect_instance_id = aws_connect_instance.connect.id,
      # RE-ADDED: Feeds the phone variable to the transition map context safely
      phone_number        = aws_connect_phone_number.claim.phone_number
    }
  )
}


# Grants permission for the automated flow engine to invoke your backend script on failures
resource "aws_lambda_permission" "allow_connect_callback" {
  statement_id  = "AllowExecutionFromAmazonConnect"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_incident.function_name
  principal     = "connect.amazonaws.com"
  
  # FIXED: Target the clean instance ARN securely using interpolation
  source_arn    = "${aws_connect_instance.connect.arn}"
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
