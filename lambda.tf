module "lambda_incident" {
  source = "git::https://github.com/narendar4100/terraform_modules//modules/lambda?ref=main"
  function_name = var.lambda_function_name
  source_zip = var.lambda_source_zip
  runtime = "python3.12"
  handler = "lambda_function.handler"
  environment = {
    CONNECT_INSTANCE_ID = var.connect_instance_id
    CONTACT_FLOW_ID = var.contact_flow_id
    DDB_TABLE_NAME = var.ddb_table_name
    DEVELOPER_PHONE_PRIMARY = var.developer_phone_primary
    DEVELOPER_PHONE_SECONDARY = var.developer_phone_secondary
  }
  tags = {
    Environment = var.environment
  }
}

