module "api_oauth2_authorizer" {
  source                 = "terraform-aws-modules/apigateway-v2/aws"
  version                = "v1.8.0"
  name                   = "${var.resource_name_prefix}-oauth2-authorizer"
  description            = "API for interacting with oauth2 lambda functions"
  protocol_type          = "HTTP"
  create_api_domain_name = false
  default_route_settings = {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 100
    throttling_rate_limit    = 100
  }

  integrations = {
    "GET /redirect-to-oauth" = {
      lambda_arn             = module.redirect_to_oauth2.lambda_function_arn
      payload_format_version = "2.0"
      integration_type       = "AWS_PROXY"
    }
    "GET /oauth2-callback"   = {
      lambda_arn             = var.authorized_lambda_function_arn
      payload_format_version = "2.0"
      integration_type       = "AWS_PROXY"
      authorizer_key         = "github_oauth2"
      authorization_type     = "CUSTOM"
    }
  }

  authorizers = {
    "github_oauth2" = {
      authorizer_type                   = "REQUEST"
      identity_sources                  = "$request.querystring.code, $request.querystring.state"
      name                              = "github-oauth2"
      authorizer_payload_format_version = "2.0"
      authorizer_uri                    = module.lambda_authorizer.lambda_function_invoke_arn
      enable_simple_responses           = true
    }
  }
}

#resource "aws_apigatewayv2_authorizer" "cognito" {
#  count            = var.users_management_type == "cognito" ? 1 : 0
#  api_id           = module.api_gateway_cognito[0].apigatewayv2_api_id
#  authorizer_type  = "JWT"
#  identity_sources = ["$request.querystring.id_token"]
#  name             = "${local.name}-wg-cognito"
#
#  jwt_configuration {
#    audience = [var.cognito_user_pool_id != null ? var.cognito_user_pool_id : aws_cognito_user_pool_client.wg-vpn[0].id ]
#    issuer   = var.cognito_user_pool_id != null ? (
#    "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${var.cognito_user_pool_id}" ) : (
#    "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${module.wg_cognito_user_pool.id}" )
#  }
#}
#

resource "aws_lambda_permission" "authorized_lambda" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = element(split(":", "arn:aws:lambda:eu-central-1:297478128798:function:github-vpn-demo-get-user-conf"),
  length(split(":", "arn:aws:lambda:eu-central-1:297478128798:function:github-vpn-demo-get-user-conf"))-1)
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_oauth2_authorizer.apigatewayv2_api_execution_arn}/*/*/*"
}
#
#resource "aws_lambda_permission" "cognito-auth-redirect" {
#  count         = var.users_management_type == "cognito" ? 1 : 0
#  statement_id  = "AllowAPIInvoke"
#  action        = "lambda:InvokeFunction"
#  function_name = "${local.name}-cognito-auth-redirect"
#  principal     = "apigateway.amazonaws.com"
#  source_arn    = "${module.api_gateway_cognito[0].apigatewayv2_api_execution_arn}/*/*/*"
#}
#
#resource "aws_lambda_permission" "redirect_2cognito" {
#  count         = var.users_management_type == "cognito" ? 1 : 0
#  statement_id  = "AllowAPIInvoke"
#  action        = "lambda:InvokeFunction"
#  function_name = "${local.name}-redirect-2cognito"
#  principal     = "apigateway.amazonaws.com"
#  source_arn    = "${module.api_gateway_cognito[0].apigatewayv2_api_execution_arn}/*/*/*"
#}