module "lambda_incident" {
    source = "./modules/lambda"
    function_name = var.lambda_function_name
    source_zip = local.lambda_artifact
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

  resource "aws_iam_role_policy" "lambda_permissions" {
    name = "${var.lambda_function_name}-permissions"
    role = module.lambda_incident.role_name
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "sns:Publish",
            "dynamodb:PutItem",
            "connect:StartOutboundVoiceContact"
          ],
          Resource = "*"
        }
      ]
    })
  }

