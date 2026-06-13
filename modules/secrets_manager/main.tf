resource "aws_secretsmanager_secret" "this" {
  name = var.name
  tags = var.tags
}
resource "aws_secretsmanager_secret_version" "this_version" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string
}
output "secret_id" {
  value = aws_secretsmanager_secret.this.id
}
