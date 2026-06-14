resource "aws_iam_role" "lex_role" {
  name = "${var.environment}-lexv2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "lexv2.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lex_policy" {
  name = "${var.environment}-lexv2-policy"
  role = aws_iam_role.lex_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "polly:SynthesizeSpeech",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "lambda:InvokeFunction"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_lexv2_bot" "incident" {
  name        = "${var.environment}-incident-bot"
  description = "Incident response bot (Lex V2)"
  role_arn    = aws_iam_role.lex_role.arn
  data_privacy {
    child_directed = false
  }
  idle_session_ttl_in_seconds = 300
}

resource "aws_lexv2_bot_locale" "en_us" {
  bot_id    = aws_lexv2_bot.incident.id
  locale_id = "en_US"
  nlu_intent_confidence_threshold = 0.40
  voice_settings {
    voice_id = "Joanna"
  }
}

resource "aws_lexv2_intent" "acknowledge" {
  name = "AcknowledgeIncidentIntent"
  bot_id = aws_lexv2_bot.incident.id
  bot_locale_id = aws_lexv2_bot_locale.en_us.id
  sample_utterances = [
    { utterance = "Yes, I acknowledge" },
    { utterance = "I acknowledge the incident" },
    { utterance = "Acknowledged" }
  ]
  intent_confirmation_setting {
    prompt_specification {
      message_groups = [
        {
          message = { plain_text_message = { value = "Are you sure you want to acknowledge this incident?" } }
        }
      ]
      allow_interrupt = true
    }
    yes_intent = {
      next_step = { type = "CloseIntent" }
    }
  }
}

resource "aws_lexv2_intent" "closing" {
  name = "ClosingIntent"
  bot_id = aws_lexv2_bot.incident.id
  bot_locale_id = aws_lexv2_bot_locale.en_us.id
  sample_utterances = [
    { utterance = "Close the incident" },
    { utterance = "This incident is resolved" },
    { utterance = "Close" }
  ]
  intent_closing_setting {
    closing_response {
      message_groups = [
        { message = { plain_text_message = { value = "Thank you. The incident will be closed." } } }
      ]
    }
  }
}

resource "aws_lexv2_slot" "incident_id" {
  name = "IncidentId"
  bot_id = aws_lexv2_bot.incident.id
  bot_locale_id = aws_lexv2_bot_locale.en_us.id
  value_elicitation_setting {
    slot_constraint = "Required"
    prompt_specification {
      message_groups = [
        { message = { plain_text_message = { value = "Please say or enter the incident ID." } } }
      ]
      max_attempts = 2
      allow_interrupt = true
    }
  }
}

resource "aws_lexv2_slot_type" "incident_type" {
  name = "IncidentType"
  description = "Type of incident (e.g. database, api, network)"
  bot_id = aws_lexv2_bot.incident.id
  bot_locale_id = aws_lexv2_bot_locale.en_us.id
  value_selection_setting {
    resolution_strategy = "TOP_RESOLUTION"
  }
  slot_type_values {
    sample_value { value = "database" }
  }
  slot_type_values {
    sample_value { value = "api" }
  }
  slot_type_values {
    sample_value { value = "network" }
  }
  slot_type_values {
    sample_value { value = "db" }
  }
  slot_type_values {
    sample_value { value = "backend" }
  }
}

resource "aws_lexv2_slot" "incident_type_slot" {
  name = "IncidentTypeSlot"
  bot_id = aws_lexv2_bot.incident.id
  bot_locale_id = aws_lexv2_bot_locale.en_us.id
  slot_type_id = aws_lexv2_slot_type.incident_type.id
  value_elicitation_setting {
    slot_constraint = "Required"
    prompt_specification {
      message_groups = [
        { message = { plain_text_message = { value = "What type of incident is this? For example: database, API, or network." } } }
      ]
      max_attempts = 2
      allow_interrupt = true
    }
  }
}

resource "aws_lexv2_bot_alias" "incident_alias" {
  name = "${var.environment}-alias"
resource "aws_lexv2_intent" "escalate" {
  name = "EscalateIntent"
  bot_id = aws_lexv2_bot.incident.id
  bot_locale_id = aws_lexv2_bot_locale.en_us.id
  sample_utterances = [
    { utterance = "escalate this incident" },
    { utterance = "I need to escalate" },
    { utterance = "please escalate" }
  ]
}

resource "aws_lexv2_intent" "repeat" {
  name = "RepeatIntent"
  bot_id = aws_lexv2_bot.incident.id
  bot_locale_id = aws_lexv2_bot_locale.en_us.id
  sample_utterances = [
    { utterance = "please repeat that" },
    { utterance = "say that again" },
    { utterance = "repeat" }
  ]
}
            bot_locale_id = aws_lexv2_bot_locale.en_us.id
            value_elicitation_setting {
              slot_constraint = "Required"
            }
          }

          resource "aws_lexv2_bot_alias" "incident_alias" {
            name = "${var.environment}-alias"
            bot_id = aws_lexv2_bot.incident.id
            bot_version = "$LATEST"
          }

          output "lex_bot_id" {
            value = aws_lexv2_bot.incident.id
          }

          output "lex_bot_alias_arn" {
            value = aws_lexv2_bot_alias.incident_alias.arn
          }
