module "dynamodb_incident_logs" {
  source = "git::git@github.com:narendar4100/terraform_modules.git?ref=main"
  table_name = var.ddb_table_name
  hash_key = "IncidentId"
  hash_key_type = "S"
  range_key = "Timestamp"
  range_key_type = "N"
  tags = {
    Environment = var.environment
  }
}

