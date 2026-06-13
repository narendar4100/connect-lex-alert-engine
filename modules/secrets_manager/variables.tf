variable "name" {
  type = string
  validation {
    condition     = length(var.name) > 0
    error_message = "name must be provided"
  }
}
variable "secret_string" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
