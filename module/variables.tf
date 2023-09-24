variable "functionName" {
  type        = string
  description = "Function name."
  nullable    = false
}

variable "runtime" {
  type        = string
  description = "The runtime environment of the fucntion."
  nullable    = false
}

variable "sourcePath" {
  type        = string
  description = "The path of the folder containing the lambda function folder."
  nullable    = false
}

variable "buildFiles" {
  type        = string
  description = "The path of the folder containing the build files."
  nullable    = false
}

variable "roleArn" {
  type        = string
  description = "The ARN of the role the lambda function will assume."
  nullable    = false
}

variable "hasDependencies" {
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
  description = "A set of API Gateway Execution ARNs that have permission to invoke the function."
  default     = []
}

variable "cloudwatchInvokeArns" {
  type        = list(any)
  description = "A set of Cloudwatch Event ARNs that have permission to invoke the function."
  default     = []
}

variable "overrideFunctionSource" {
  type        = string
  description = "Use this instead of the function name to locate the source code."
  default     = null
}
