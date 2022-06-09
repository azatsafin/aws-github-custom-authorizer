locals {
  ssm_path_invoke_url = "/${var.resource_name_prefix}/api-invoke-url"
}

resource "aws_ssm_parameter" "api_gateway" {
  data_type   = "text"
  description = "Invoke URL"
  name        = local.ssm_path_invoke_url
  type        = "String"
  value       = "${module.api_oauth2_authorizer.default_apigatewayv2_stage_invoke_url}oauth2-callback"
}