variable "function_name" {
  type        = string
  description = "Function name."
  nullable    = false
}

variable "runtime" {
  type        = string
  description = "The runtime environment of the fucntion."
  nullable    = false
}

variable "source_path" {
  type        = string
  description = "The path of the folder containing the lambda function folder."
  nullable    = false
}

variable "build_files" {
  type        = string
  description = "The path of the folder containing the build files."
  nullable    = false
}

variable "role_arn" {
  type        = string
  description = "The ARN of the role the lambda function will assume."
  nullable    = false
}

variable "has_dependencies" {
  type        = bool
  description = "True if the function has dependencies in the 'dependencies' folder."
  default     = false
}

variable "timeout" {
  type        = number
  description = "The timeout limit of the function."
  default     = 60
}

variable "environmentVariables" {
  type        = map(string)
  description = "Environment variables for the function."
  default     = {}
}

variable "apiGatewayInvokeArns" {
  type        = list(any)
  description = "A set of Cloudwatch Event ARNs that have permission to invoke the function."
  default     = []
}

variable "cloudwatchInvokeArns" {
  type        = list(any)
  description = "A set of API Gateway Execution ARNs that have permission to invoke the function."
  default     = []
}
