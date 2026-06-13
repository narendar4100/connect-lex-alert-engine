variable "name" {
  type = string
  validation {
    condition     = length(var.name) > 0
    error_message = "name must be provided"
  }
}
variable "integration_uri" {
  type = string
}
variable "route_key" {
  type    = string
  default = "$default"
}
variable "tags" {
  type    = map(string)
  default = {}
}
