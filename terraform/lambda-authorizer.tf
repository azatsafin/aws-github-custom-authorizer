locals {
  lambda_authorizer_function_name = "${var.resource_name_prefix}-lambda-authorizer"
}

module "lambda_authorizer" {
  source          = "terraform-aws-modules/lambda/aws"
  version         = "3.2.1"
  create_package  = true
  create_role     = true
  create          = true
  create_layer    = false
  create_function = true
  publish         = true
  function_name   = local.lambda_authorizer_function_name
  runtime         = "python3.9"
  handler         = "app.handler"
  memory_size     = 512
  timeout         = 30
  package_type    = "Zip"
  source_path     = "${path.module}/../lambdas/lambda_authorizer"

  environment_variables = {
    CLIENT_ID            = var.client_id
    CLIENT_SECRET        = var.client_secret
    DYNAMO_DB_TABLE_NAME = local.dynamodb_table_name
    SSM_PATH_INVOKE_URL  = local.ssm_path_invoke_url
    GITHUB_ORG           = var.github_org
  }
}

resource "aws_iam_policy" "allow_read_dynamodb" {
  name = "${var.resource_name_prefix}-allow-dynamodb-read-oauth-authorizer"
  path = "/${var.resource_name_prefix}/"
  policy = jsonencode(
    {
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:DescribeTable",
            "dynamodb:GetItem",
            "dynamodb:Query",
          ],
          "Resource" : "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:table/${local.dynamodb_table_name}"
        },
        {
          "Effect" : "Allow",
          "Action" : "ssm:GetParameter",
          "Resource" : "arn:aws:ssm:${local.region}:${local.account_id}:parameter${local.ssm_path_invoke_url}*"
        }
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role_policy_attachment" "allow_read_dynamodb_4oauth_authorizer" {
  role       = module.lambda_authorizer.lambda_role_name
  policy_arn = aws_iam_policy.allow_read_dynamodb.arn
}

resource "aws_lambda_permission" "lambda_authorizer" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_authorizer.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${module.api_oauth2_authorizer.apigatewayv2_api_execution_arn}/authorizers/*"
}