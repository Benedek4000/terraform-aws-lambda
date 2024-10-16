data "archive_file" "lambdaLayer" {
  count       = var.hasDependencies ? 1 : 0
  type        = "zip"
  source_dir  = "${var.sourcePath}/${var.functionName}/dependencies"
  output_path = "${var.buildFiles}/${var.functionName}_dependencies.zip"
}

resource "aws_lambda_layer_version" "lambdaLayer" {
  count               = var.hasDependencies ? 1 : 0
  layer_name          = "${var.functionName}-dependencies"
  filename            = data.archive_file.lambdaLayer[count.index].output_path
  compatible_runtimes = [var.runtime]

  source_code_hash = data.archive_file.lambdaLayer[count.index].output_base64sha256
}

data "archive_file" "lambda_archive" {
  type                    = "zip"
  source_content_filename = "${var.functionName}.py"
  source_content          = var.overrideFunctionSource == null ? (file("${var.sourcePath}/${var.functionName}/handler.py")) : (file("${var.sourcePath}/${var.overrideFunctionSource}/handler.py"))
  output_path             = "${var.buildFiles}/${var.functionName}.zip"
}

resource "aws_lambda_function" "function" {
  filename      = data.archive_file.lambda_archive.output_path
  function_name = var.functionName
  role          = var.roleArn
  handler       = "${var.functionName}.handler"
  timeout       = var.timeout
  layers        = var.hasDependencies ? [aws_lambda_layer_version.lambdaLayer[0].arn] : null
  runtime       = var.runtime

  environment {
    variables = var.environmentVariables
  }

  source_code_hash = data.archive_file.lambda_archive.output_base64sha256
}

resource "aws_lambda_permission" "cloudwatch_permission" {
  for_each = { for k, v in var.cloudwatchInvokeArns : k => v }

  source_arn    = each.value
  statement_id  = "AllowCloudWatchInvoke-${element(split("/", each.value), length(split("/", each.value)) - 1)}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "events.amazonaws.com"
}

resource "aws_lambda_permission" "api_gateway_permission" {
  for_each = { for k, v in var.apiGatewayInvokeArns : k => v }

  source_arn    = "${each.value}/*"
  statement_id  = "AllowAPIGatewayInvoke-${element(split(":", each.value), length(split(":", each.value)) - 1)}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "apigateway.amazonaws.com"
}
