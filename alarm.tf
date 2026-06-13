resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx" {
  alarm_name = "${var.environment}-api-gateway-5xx"
  namespace = "AWS/ApiGateway"
  metric_name = "5XXError"
  statistic = "Sum"
  period = 60
  evaluation_periods = 1
  threshold = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data = "notBreaching"
  alarm_description = "Alarm when API Gateway returns 5XX errors"
}

resource "aws_cloudwatch_event_rule" "alarm_to_lambda" {
  name = "${var.environment}-alarm-to-lambda"
  event_pattern = jsonencode({
    "source" = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    "detail" = {
      "alarmName" = [aws_cloudwatch_metric_alarm.api_gateway_5xx.alarm_name]
      "state" = {
        "value" = ["ALARM"]
      }
    }
  })
}

data "aws_lambda_function" "target" {
  function_name = var.lambda_function_name
}

resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule = aws_cloudwatch_event_rule.alarm_to_lambda.name
  target_id = "InvokeLambda"
  arn = data.aws_lambda_function.target.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id = "AllowExecutionFromEventBridge"
  action = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.target.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.alarm_to_lambda.arn
}
