resource "aws_iam_role" "lex_role" {
  name = "${var.environment}-lexv2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lexv2.amazonaws.com" }
        Action    = "sts:AssumeRole"
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

resource "aws_lexv2models_bot" "incident" {
  name                        = "${var.environment}-incident-bot"
  description                 = "Incident response bot (Lex V2)"
  role_arn                    = aws_iam_role.lex_role.arn
  idle_session_ttl_in_seconds = 300

  data_privacy {
    child_directed = false
  }
}

resource "aws_lexv2models_bot_locale" "en_us" {
  bot_id                           = aws_lexv2models_bot.incident.id
  bot_version                      = "DRAFT"
  locale_id                        = "en_US"
  n_lu_intent_confidence_threshold = 0.40

  voice_settings {
    voice_id = "Joanna"
  }
}

resource "aws_lexv2models_bot_locale" "en_gb" {
  bot_id                           = aws_lexv2models_bot.incident.id
  bot_version                      = "DRAFT"
  locale_id                        = "en_GB"
  n_lu_intent_confidence_threshold = 0.40

  voice_settings {
    voice_id = "Amy"
  }
}

resource "aws_lexv2models_intent" "acknowledge" {
  name        = "AcknowledgeIncidentIntent"
  bot_id      = aws_lexv2models_bot.incident.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.en_us.locale_id

  sample_utterance { utterance = "Yes, I acknowledge" }
  sample_utterance { utterance = "I acknowledge the incident" }
  sample_utterance { utterance = "Acknowledged" }
}

resource "aws_lexv2models_intent" "closing" {
  name        = "ClosingIntent"
  bot_id      = aws_lexv2models_bot.incident.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.en_us.locale_id

  sample_utterance { utterance = "Close the incident" }
  sample_utterance { utterance = "This incident is resolved" }
  sample_utterance { utterance = "Close" }
}

resource "aws_lexv2models_intent" "escalate" {
  name        = "EscalateIntent"
  bot_id      = aws_lexv2models_bot.incident.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.en_us.locale_id

  sample_utterance { utterance = "escalate this incident" }
  sample_utterance { utterance = "I need to escalate" }
  sample_utterance { utterance = "please escalate" }
}

resource "aws_lexv2models_intent" "repeat" {
  name        = "CustomRepeatIntent"
  bot_id      = aws_lexv2models_bot.incident.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.en_us.locale_id

  sample_utterance { utterance = "please repeat that" }
  sample_utterance { utterance = "say that again" }
  sample_utterance { utterance = "repeat" }
}

resource "aws_lexv2models_slot_type" "incident_type" {
  name        = "IncidentType"
  description = "Type of incident (e.g. database, api, network)"
  bot_id      = aws_lexv2models_bot.incident.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.en_us.locale_id

  value_selection_setting {
    resolution_strategy = "TopResolution"
  }

  slot_type_values {
    sample_value {
      value = "database"
    }
  }

  slot_type_values {
    sample_value {
      value = "api"
    }
  }

  slot_type_values {
    sample_value {
      value = "network"
    }
  }

  slot_type_values {
    sample_value {
      value = "db"
    }
  }

  slot_type_values {
    sample_value {
      value = "backend"
    }
  }
}

resource "aws_lexv2models_slot" "incident_type" {
  name         = "IncidentTypeSlot"
  bot_id       = aws_lexv2models_bot.incident.id
  bot_version  = "DRAFT"
  locale_id    = aws_lexv2models_bot_locale.en_us.locale_id
  intent_id    = aws_lexv2models_intent.acknowledge.intent_id
  slot_type_id = aws_lexv2models_slot_type.incident_type.slot_type_id

  value_elicitation_setting {
    slot_constraint = "Required"
    prompt_specification {
      max_retries                = 2 
      allow_interrupt            = true
      message_selection_strategy = "Random"

      message_group {
        message {
          plain_text_message { value = "What type of incident is this? For example: database, API, or network." }
        }
      }

      prompt_attempts_specification {
        map_block_key   = "Initial"
        allow_interrupt = true
        allowed_input_types {
          allow_audio_input = true
          allow_dtmf_input  = true
        }
        audio_and_dtmf_input_specification {
          start_timeout_ms = 4000
          audio_specification {
            end_timeout_ms = 640
            max_length_ms  = 15000
          }
          dtmf_specification {
            deletion_character = "*"
            end_character      = "#"
            end_timeout_ms     = 5000
            max_length         = 513
          }
        }
        text_input_specification {
          start_timeout_ms = 30000
        }
      }

      prompt_attempts_specification {
        map_block_key   = "Retry1"
        allow_interrupt = true
        allowed_input_types {
          allow_audio_input = true
          allow_dtmf_input  = true
        }
        audio_and_dtmf_input_specification {
          start_timeout_ms = 4000
          audio_specification {
            end_timeout_ms = 640
            max_length_ms  = 15000
          }
          dtmf_specification {
            deletion_character = "*"
            end_character      = "#"
            end_timeout_ms     = 5000
            max_length         = 513
          }
        }
        text_input_specification {
          start_timeout_ms = 30000
        }
      }

      prompt_attempts_specification {
        map_block_key   = "Retry2"
        allow_interrupt = true
        allowed_input_types {
          allow_audio_input = true
          allow_dtmf_input  = true
        }
        audio_and_dtmf_input_specification {
          start_timeout_ms = 4000
          audio_specification {
            end_timeout_ms = 640
            max_length_ms  = 15000
          }
          dtmf_specification {
            deletion_character = "*"
            end_character      = "#"
            end_timeout_ms     = 5000
            max_length         = 513
          }
        }
        text_input_specification {
          start_timeout_ms = 30000
        }
      }
    }
  }
}

resource "aws_lexv2models_slot" "incident_id" {
  name         = "IncidentId"
  bot_id       = aws_lexv2models_bot.incident.id
  bot_version  = "DRAFT"
  locale_id    = aws_lexv2models_bot_locale.en_us.locale_id
  intent_id    = aws_lexv2models_intent.acknowledge.intent_id
  slot_type_id = "AMAZON.AlphaNumeric"

  value_elicitation_setting {
    slot_constraint = "Required"
    prompt_specification {
      max_retries                = 2 
      allow_interrupt            = true
      message_selection_strategy = "Random"

      message_group {
        message {
          plain_text_message { value = "Please say or enter the incident ID." }
        }
      }

      prompt_attempts_specification {
        map_block_key   = "Initial"
        allow_interrupt = true
        allowed_input_types {
          allow_audio_input = true
          allow_dtmf_input  = true
        }
        audio_and_dtmf_input_specification {
          start_timeout_ms = 4000
          audio_specification {
            end_timeout_ms = 640
            max_length_ms  = 15000
          }
          dtmf_specification {
            deletion_character = "*"
            end_character      = "#"
            end_timeout_ms     = 5000
            max_length         = 513
          }
        }
        text_input_specification {
          start_timeout_ms = 30000
        }
      }

      prompt_attempts_specification {
        map_block_key   = "Retry1"
        allow_interrupt = true
        allowed_input_types {
          allow_audio_input = true
          allow_dtmf_input  = true
        }
        audio_and_dtmf_input_specification {
          start_timeout_ms = 4000
          audio_specification {
            end_timeout_ms = 640
            max_length_ms  = 15000
          }
          dtmf_specification {
            deletion_character = "*"
            end_character      = "#"
            end_timeout_ms     = 5000
            max_length         = 513
          }
        }
        text_input_specification {
          start_timeout_ms = 30000
        }
      }

      prompt_attempts_specification {
        map_block_key   = "Retry2"
        allow_interrupt = true
        allowed_input_types {
          allow_audio_input = true
          allow_dtmf_input  = true
        }
        audio_and_dtmf_input_specification {
          start_timeout_ms = 4000
          audio_specification {
            end_timeout_ms = 640
            max_length_ms  = 15000
          }
          dtmf_specification {
            deletion_character = "*"
            end_character      = "#"
            end_timeout_ms     = 5000
            max_length         = 513
          }
        }
        text_input_specification {
          start_timeout_ms = 30000
        }
      }
    }
  }
}

output "lex_bot_id" {
  value = aws_lexv2models_bot.incident.id
}
