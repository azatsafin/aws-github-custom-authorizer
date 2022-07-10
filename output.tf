output "oauth2_callback_url" {
  sensitive = false
  value = "${module.api_oauth2_authorizer.default_apigatewayv2_stage_invoke_url}oauth2-callback"
}

output "oauth2_login" {
  value = "${module.api_oauth2_authorizer.default_apigatewayv2_stage_invoke_url}redirect-to-oauth"
}