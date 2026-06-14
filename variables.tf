variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "developer_phone_primary" {
  type    = string
  default = "+15555550100"
}

variable "developer_phone_secondary" {
  type    = string
  default = "+15555550200"
}

variable "lambda_function_name" {
  type    = string
  default = "incident_alert_handler"
}

variable "lambda_source_zip" {
  type    = string
  default = "artifacts/incident_alert_lambda.zip"
}

variable "connect_instance_id" {
  type    = string
  default = ""
}

variable "contact_flow_id" {
  type    = string
  default = ""
}

variable "ddb_table_name" {
  type    = string
  default = "IncidentResponseLogs"
}

variable "admin_password" {
  type    = string
  default = "ChangeMe!123"
}

variable "claim_country_code" {
  type    = string
  default = "US"
}

variable "lex_v2_bot_alias_arn" {
  type = string
  default = ""
}
