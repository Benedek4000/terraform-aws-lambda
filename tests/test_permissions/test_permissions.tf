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


data "aws_route53_zone" "zone" {
  name = file("${path.root}/zone_name.txt")
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "${local.domainTag}${data.aws_route53_zone.zone.name}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.resource_record_name]
}


resource "aws_api_gateway_rest_api" "api" {
  name = local.functionName
  body = file("${path.root}/api.json")
  endpoint_configuration {
    types = ["EDGE"]
  }
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name     = aws_acm_certificate.cert.domain_name
  certificate_arn = aws_acm_certificate.cert.arn
  security_policy = "TLS_1_2"
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

resource "aws_api_gateway_method_settings" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled                            = true
    logging_level                              = "INFO"
    throttling_burst_limit                     = 100
    throttling_rate_limit                      = 50
    caching_enabled                            = false
    cache_ttl_in_seconds                       = 300
    cache_data_encrypted                       = true
    data_trace_enabled                         = false
    require_authorization_for_cache_control    = true
    unauthorized_cache_control_header_strategy = "SUCCEED_WITH_RESPONSE_HEADER"
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

resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
}

##### TESTS #####

module "permissions" {
  source = "../.."

  function_name        = local.functionName
  source_path          = local.lambdaFileSource
  build_files          = local.buildFileSource
  runtime              = "python3.11"
  role_arn             = aws_iam_role.role.arn
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
