terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}

locals {
  functionName     = "test-permissions"
  lambdaFileSource = "${path.root}/../lambda_functions"
  buildFileSource  = "${path.root}/../build_files"
  predefinedPolicies = toset([
    "AmazonEC2FullAccess",
    "AmazonSSMFullAccess",
    "AmazonRoute53FullAccess",
  ])
  domainTag = "test."
  stageName = "test-lambda"
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

##### CLOUDWATCH EVENT #####

resource "aws_cloudwatch_event_rule" "triggerLambda" {
  name                = local.functionName
  description         = local.functionName
  schedule_expression = "cron(* * * * ? *)"
}

resource "aws_cloudwatch_event_target" "invokeLambda" {
  rule  = aws_cloudwatch_event_rule.triggerLambda.name
  arn   = module.permissions.function.arn
  input = jsonencode({ "message" : "Triggered by CloudWatch Event Rule" })
}

##### API GATEWAY #####

resource "aws_api_gateway_rest_api" "api" {
  name = local.functionName
  body = file("${path.root}/api.json")
  endpoint_configuration {
    types = ["EDGE"]
  }
}

resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = local.stageName

  variables = {
    apiSpecHash = sha1(file("${path.root}/api.json"))
  }
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(file("${path.root}/api.json"))
  }

  lifecycle {
    create_before_destroy = true
  }
}

##### TESTS #####

module "permissions" {
  source = "../../module"

  functionName         = local.functionName
  sourcePath           = local.lambdaFileSource
  buildFiles           = local.buildFileSource
  runtime              = "python3.11"
  roleArn              = aws_iam_role.role.arn
  cloudwatchInvokeArns = [aws_cloudwatch_event_rule.triggerLambda.arn]
  apiGatewayInvokeArns = [aws_api_gateway_rest_api.api.execution_arn]
}

resource "test_assertions" "tests" {
  component = local.functionName

  equal "functionName" {
    description = "function name"
    got         = module.permissions.function.function_name
    want        = local.functionName
  }

  equal "runtime" {
    description = "runtime"
    got         = module.permissions.function.runtime
    want        = "python3.11"
  }

  equal "timeout" {
    description = "timeout"
    got         = module.permissions.function.timeout
    want        = 60
  }

  equal "roleArn" {
    description = "role arn"
    got         = module.permissions.function.role
    want        = aws_iam_role.role.arn
  }
}
