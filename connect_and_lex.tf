resource "aws_iam_role" "lex_role" {
  name = "${var.environment}-lex-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lexv2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lex_policy" {
  name = "${var.environment}-lex-policy"
  role = aws_iam_role.lex_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "polly:SynthesizeSpeech",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_connect_instance" "connect" {
  identity_management_type = "CONNECT_MANAGED"
  inbound_calls_enabled = true
  outbound_calls_enabled = true
  instance_alias = "${var.environment}-connect"
}

resource "aws_connect_user" "admin" {
  instance_id = aws_connect_instance.connect.id
  username = "connect_admin"
  password = "ChangeMe!123"
  identity_info = {
    first_name = "Admin"
    last_name = "User"
  }
}

resource "aws_lexv2_bot" "incident_bot" {
  bot_name = "${var.environment}-incident-bot"
  role_arn = aws_iam_role.lex_role.arn
  data_privacy = {
    child_directed = false
  }
}

resource "aws_lexv2_bot_locale" "en_us" {
  bot_id = aws_lexv2_bot.incident_bot.id
  locale_id = "en_US"
  nlu_intent_confidence_threshold = 0.4
  voice_settings = {
    voice_id = "Joanna"
  }
  intent {
    name = "AcknowledgeIncidentIntent"
    sample_utterances = ["yes, checking","incident acknowledged"]
  }
  intent {
    name = "AMAZON.FallbackIntent"
    sample_utterances = []
  }
  intent {
    name = "ClosingIntent"
    sample_utterances = ["closing","goodbye","end call"]
  }
}

resource "aws_lexv2_bot_alias" "incident_alias" {
  bot_id = aws_lexv2_bot.incident_bot.id
  bot_version = "$LATEST"
  name = "${var.environment}-alias"
  description = "Alias for connect integration"
  locale_settings = {
    locale_id = aws_lexv2_bot_locale.en_us.locale_id
    enabled = true
  }
}
