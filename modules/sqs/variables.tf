variable "name" {
  type = string
  validation {
    condition     = length(var.name) > 0
    error_message = "name must be provided"
  }
}
variable "visibility_timeout_seconds" {
  type    = number
  default = 30
}
variable "message_retention_seconds" {
  type    = number
  default = 345600
}
variable "tags" {
  type    = map(string)
  default = {}
}
