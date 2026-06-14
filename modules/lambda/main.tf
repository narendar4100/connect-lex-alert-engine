resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  filename      = var.source_zip != "" ? var.source_zip : null
  s3_bucket     = var.source_zip == "" ? (var.s3_bucket != "" ? var.s3_bucket : null) : null
  s3_key        = var.source_zip == "" ? (var.s3_key != "" ? var.s3_key : null) : null
  handler       = var.handler
  runtime       = var.runtime
  role          = aws_iam_role.lambda_role.arn
  timeout       = var.timeout
  memory_size   = var.memory_size
  environment {
    variables = var.environment
  }
  tags = var.tags
}
