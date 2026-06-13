variable "table_name" {
  type = string
  validation {
    condition     = length(var.table_name) > 0
    error_message = "table_name must be provided"
  }
}
variable "hash_key" {
  type = string
  default = "Id"
}
variable "hash_key_type" {
  type = string
  default = "S"
  validation {
    condition     = contains(["S","N","B"], var.hash_key_type)
    error_message = "hash_key_type must be S, N, or B"
  }
}
variable "range_key" {
  type = string
  default = "Timestamp"
}
variable "range_key_type" {
  type = string
  default = "N"
  validation {
    condition     = contains(["S","N","B"], var.range_key_type)
    error_message = "range_key_type must be S, N, or B"
  }
}
variable "read_capacity" {
  type = number
  default = 5
}
variable "write_capacity" {
  type = number
  default = 5
}
variable "billing_mode" {
  type = string
  default = "PROVISIONED"
}
variable "tags" {
  type = map(string)
  default = {}
}
