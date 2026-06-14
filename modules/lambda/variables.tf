variable "function_name" {
  type = string
  validation {
    condition     = length(var.function_name) > 0
    error_message = "function_name must be provided"
  }
}
variable "s3_bucket" {
  type = string
  default = ""
}
variable "s3_key" {
  type = string
  default = ""
}
variable "source_zip" {
  type    = string
  default = ""
}
variable "handler" {
  type    = string
  default = "lambda_function.handler"
}
variable "runtime" {
  type    = string
  default = "python3.12"
}
variable "timeout" {
  type    = number
  default = 30
}
variable "memory_size" {
  type    = number
  default = 128
}
variable "environment" {
  type    = map(string)
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
