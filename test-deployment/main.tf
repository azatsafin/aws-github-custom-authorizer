module "github_authorizer" {
  source                         = "../terraform"
  client_id                      = "22e7777777e777bb66ee"
  client_secret                  = "client_secret_has_40ty_characters"
  authorized_lambda_function_arn = "arn:aws:lambda:eu-central-1:your-account-id:function:test-oauth2-authorization"
}

provider "aws" {
  region = "eu-central-1"
}

output "oauth2_callback_url" {
  value = module.github_authorizer.oauth2_callback_url
}

output "redirect-to-oauth" {
  value = module.github_authorizer.oauth2_login
}