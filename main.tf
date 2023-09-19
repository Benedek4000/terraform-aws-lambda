data "archive_file" "lambda_layer" {
  count       = var.has_dependencies ? 1 : 0
  type        = "zip"
  source_dir  = "${var.source_path}/${var.function_name}/dependencies"
  output_path = "${var.build_files}/${var.function_name}_dependencies.zip"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  count               = var.has_dependencies ? 1 : 0
  layer_name          = "${var.function_name}-dependencies"
  filename            = data.archive_file.lambda_layer[count.index].output_path
  compatible_runtimes = [var.runtime]

  source_code_hash = data.archive_file.lambda_layer[count.index].output_base64sha256
}

data "archive_file" "lambda_archive" {
  type                    = "zip"
  source_content_filename = "${var.function_name}.py"
  source_content          = var.overrideFunctionSource == null ? (file("${var.source_path}/${var.function_name}/handler.py")) : (file("${var.source_path}/${var.overrideFunctionSource}/handler.py"))
  output_path             = "${var.build_files}/${var.function_name}.zip"
}

resource "aws_lambda_function" "function" {
  filename      = data.archive_file.lambda_archive.output_path
  function_name = var.function_name
  role          = var.role_arn
  handler       = "${var.function_name}.handler"
  timeout       = var.timeout
  layers        = var.has_dependencies ? [aws_lambda_layer_version.lambda_layer[0].arn] : null
  runtime       = var.runtime

  environment {
    variables = var.environmentVariables
  }

  source_code_hash = data.archive_file.lambda_archive.output_base64sha256
}

resource "aws_lambda_permission" "cloudwatch_permission" {
  for_each = { for k, v in var.cloudwatchInvokeArns : k => v }

  source_arn    = each.value
  statement_id  = "AllowCloudWatchInvoke-${var.function_name}-${element(split("/", each.value), length(split("/", each.value)) - 1)}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "events.amazonaws.com"
}

resource "aws_lambda_permission" "api_gateway_permission" {
  for_each = { for k, v in var.apiGatewayInvokeArns : k => v }

  source_arn    = "${each.value}/*"
  statement_id  = "AllowAPIGatewayInvoke-${var.function_name}-${element(split(":", each.value), length(split(":", each.value)) - 1)}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "apigateway.amazonaws.com"
}
