module "dynamodb_incident_logs" {
  source = "../modules/dynamodb"
  table_name = var.ddb_table_name
  hash_key = "IncidentId"
  hash_key_type = "S"
  range_key = "Timestamp"
  range_key_type = "N"
  tags = {
    Environment = var.environment
  }
}
module "dynamodb_incident_logs" {
  source = "../modules/dynamodb"
  table_name = var.ddb_table_name
  hash_key = "IncidentId"
  hash_key_type = "S"
  range_key = "Timestamp"
  range_key_type = "N"
  tags = {
    Environment = var.environment
  }
}
