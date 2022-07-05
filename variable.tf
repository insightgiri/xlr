#################################### Common variables ##################################################
variable "resource_group_name" {
  type        = string
  description = "Resource group name."
  default     = "aot-n-zeaus-sceptre-xlrelease-rg"
}

variable "resource_group_location" {
  type        = string
  description = "Location where the storage accounts will be created."
  default     = "East US"
}
