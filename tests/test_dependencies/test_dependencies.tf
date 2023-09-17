terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}

locals {
  functionName     = "test-dependencies"
  lambdaFileSource = "${path.root}/../lambda_functions"
  buildFileSource  = "${path.root}/../build_files"
  predefinedPolicies = toset([
    "AmazonEC2FullAccess",
    "AmazonSSMFullAccess",
    "AmazonRoute53FullAccess",
  ])
}

##### ROLE #####

data "aws_iam_policy_document" "AssumeRoleDetails" {
  statement {
    sid     = "AssumeRoleDetails"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = local.functionName
  assume_role_policy = data.aws_iam_policy_document.AssumeRoleDetails.json
}

data "aws_iam_policy" "predefinedPolicies" {
  for_each = local.predefinedPolicies
  name     = each.value
}

resource "aws_iam_role_policy_attachment" "predefinedPolicies" {
  for_each   = data.aws_iam_policy.predefinedPolicies
  role       = aws_iam_role.role.name
  policy_arn = each.value.arn
}

##### TESTS #####

module "dependencies" {
  source = "../.."

  function_name    = local.functionName
  source_path      = local.lambdaFileSource
  build_files      = local.buildFileSource
  runtime          = "python3.11"
  role_arn         = aws_iam_role.role.arn
  has_dependencies = true
}

resource "test_assertions" "tests" {
  component = local.functionName

  equal "functionName" {
    description = "function name"
    got         = module.dependencies.function.function_name
    want        = local.functionName
  }

  equal "runtime" {
    description = "runtime"
    got         = module.dependencies.function.runtime
    want        = "python3.11"
  }

  equal "timeout" {
    description = "timeout"
    got         = module.dependencies.function.timeout
    want        = 60
  }

  equal "roleArn" {
    description = "role arn"
    got         = module.dependencies.function.role
    want        = aws_iam_role.role.arn
  }
}
