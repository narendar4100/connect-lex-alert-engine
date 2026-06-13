variable "name" {
  type = string
  validation {
    condition     = length(var.name) > 0
    error_message = "name must be provided"
  }
}
variable "versioning" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
