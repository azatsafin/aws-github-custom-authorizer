locals {
  dynamodb_table_name = "${var.resource_name_prefix}-oauth2-authorizer"
}

module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"
  version = "v2.0.0"
  name     = local.dynamodb_table_name
  hash_key = "state"

  billing_mode = "PAY_PER_REQUEST"
  ttl_attribute_name = "ttl"
  ttl_enabled = true

  attributes = [
    {
      name = "state"
      type = "S"
    }
  ]

  tags = merge(
    var.tags,
    {
      "Name" = format("%s", "${var.resource_name_prefix}-oauth2-authorizer")
    }
  )
}