# Terraform AWS Lambda Module

TODO:

-   more accurate test-permissions

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.11 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.4.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_lambda_function.function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_layer_version.lambda_layer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource |
| [aws_lambda_permission.api_gateway_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.cloudwatch_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [archive_file.lambda_archive](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.lambda_layer](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apiGatewayInvokeArns"></a> [apiGatewayInvokeArns](#input\_apiGatewayInvokeArns) | A set of API Gateway Execution ARNs that have permission to invoke the function. | `list(any)` | `[]` | no |
| <a name="input_build_files"></a> [build\_files](#input\_build\_files) | The path of the folder containing the build files. | `string` | n/a | yes |
| <a name="input_cloudwatchInvokeArns"></a> [cloudwatchInvokeArns](#input\_cloudwatchInvokeArns) | A set of Cloudwatch Event ARNs that have permission to invoke the function. | `list(any)` | `[]` | no |
| <a name="input_environmentVariables"></a> [environmentVariables](#input\_environmentVariables) | Environment variables for the function. | `map(string)` | `{}` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Function name. | `string` | n/a | yes |
| <a name="input_has_dependencies"></a> [has\_dependencies](#input\_has\_dependencies) | True if the function has dependencies in the 'dependencies' folder. | `bool` | `false` | no |
| <a name="input_overrideFunctionSource"></a> [overrideFunctionSource](#input\_overrideFunctionSource) | Use this instead of the function name to locate the source code. | `string` | `null` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | The ARN of the role the lambda function will assume. | `string` | n/a | yes |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | The runtime environment of the fucntion. | `string` | n/a | yes |
| <a name="input_source_path"></a> [source\_path](#input\_source\_path) | The path of the folder containing the lambda function folder. | `string` | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | The timeout limit of the function. | `number` | `60` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dependencyLayer"></a> [dependencyLayer](#output\_dependencyLayer) | The lambda layer. |
| <a name="output_function"></a> [function](#output\_function) | The lambda function. |
<!-- END_TF_DOCS -->
