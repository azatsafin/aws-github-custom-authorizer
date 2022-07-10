variable "resource_name_prefix" {
  default = "module"
  description = "Specify your project name here, all resource name will be used this string as a prefix in resource names ex:module-resource-name"
}

variable "client_id" {
  type = string
  description = "ClientID of your auth app"
}

variable "client_secret" {
  type = string
  description = "ClientSecret of your auth app"
}

variable "tags" {
  type = map(string)
  description = "nested tags for resources"
  default = {}
}

variable "github_org" {
  type = string
  description = "The name of your github organization"
  default = "provectus"
}

variable "authorized_lambda_function_arn" {
  type = string
  description = "The ARN of lambda function that will be executed if called user is a member of provided GitHub org"
}