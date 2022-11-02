terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "service_accounts" {
  type = list(object({
    name      = string
    policy    = string
  }))
}

resource "aws_iam_user" "service_accounts" {
  for_each = { for sa in var.service_accounts : sa.name => sa }
  name     = each.value.name
}

resource "aws_iam_user_policy" "service_accounts" {
  for_each = { for sa in var.service_accounts : sa.name => sa }
  name     = each.value.name
  user     = aws_iam_user.service_accounts[each.value.name].name
  policy   = each.value.policy
}

resource "aws_iam_access_key" "service_accounts" {
  for_each = { for sa in var.service_accounts : sa.name => sa }
  user     = aws_iam_user.service_accounts[each.value.name].name
}

resource "local_file" "service_accounts" {
  for_each = { for sa in var.service_accounts : sa.name => sa }
  filename = "./aws-iam-users/${each.value.name}.json"
  content = jsonencode({
    "aws_access_key_id"     = aws_iam_access_key.service_accounts[each.value.name].id
    "aws_secret_access_key" = aws_iam_access_key.service_accounts[each.value.name].secret
  })
}