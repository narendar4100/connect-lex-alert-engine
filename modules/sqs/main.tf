resource "aws_sqs_queue" "this" {
  name = var.name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  tags = var.tags
}
output "queue_url" {
  value = aws_sqs_queue.this.id
}
