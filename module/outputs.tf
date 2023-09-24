output "function" {
  description = "The lambda function."
  value       = aws_lambda_function.function
}

output "dependencyLayer" {
  description = "The lambda layer."
  value       = var.hasDependencies ? aws_lambda_layer_version.lambdaLayer[0] : null
}
