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

resource "aws_lambda_permission" "authorized_lambda" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = element(split(":", var.authorized_lambda_function_arn),
  length(split(":", var.authorized_lambda_function_arn))-1)
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_oauth2_authorizer.apigatewayv2_api_execution_arn}/*/*/*"
}
