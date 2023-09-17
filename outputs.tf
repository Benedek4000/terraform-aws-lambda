output "function" {
  description = "The lambda function."
  value       = aws_lambda_function.function
}

output "dependencyLayer" {
  description = "The lambda layer."
  value       = var.has_dependencies ? aws_lambda_layer_version.lambda_layer[0] : null
}
