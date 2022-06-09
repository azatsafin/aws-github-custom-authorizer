 locals {
  redirect_oauth2_function_name = "${var.resource_name_prefix}-redirect-2authenticator"
}

module "redirect_to_oauth2" {
  source          = "terraform-aws-modules/lambda/aws"
  version         = "3.2.1"
  create_package  = true
  create_role     = true
  create          = true
  create_layer    = false
  create_function = true
  publish         = true
  function_name   = local.redirect_oauth2_function_name
  runtime         = "python3.9"
  handler         = "app.handler"
  memory_size     = 512
  timeout         = 30
  package_type    = "Zip"
  source_path     = "${path.module}/../lambdas/redirect_to_oauth2"

  environment_variables = {
    CLIENT_ID            = var.client_id
    CLIENT_SECRET        = var.client_secret
    DYNAMO_DB_TABLE_NAME = local.dynamodb_table_name
    SSM_PATH_INVOKE_URL  = local.ssm_path_invoke_url
  }
}

resource "aws_iam_policy" "allow_dynamodb" {
  name = "${var.resource_name_prefix}-allow-dynamodb-oauth-authorizer"
  path = "/${var.resource_name_prefix}/"
  policy = jsonencode(
    {
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:UpdateTimeToLive",
            "dynamodb:PutItem",
            "dynamodb:DescribeTable",
            "dynamodb:GetItem",
            "dynamodb:Query",
            "dynamodb:UpdateItem"
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

resource "aws_iam_role_policy_attachment" "allow_dynamodb_4oauth_authorizer" {
  role       = module.redirect_to_oauth2.lambda_role_name
  policy_arn = aws_iam_policy.allow_dynamodb.arn
}