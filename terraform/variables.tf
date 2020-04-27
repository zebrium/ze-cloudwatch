variable "aws_access_key_id" {
  default = "<AWS_ACCESS_KEY>"
}

variable "aws_secret_access_key" {
  default = "<AWS_SECRET_ACCESS_KEY>"
}

variable "region" {
  default = "<YOUR_AWS_REGION>"
}

variable "lambda_function_name" {
  default = "<YOUR_NEW_LAMBDA_FUNCTION_NAME>"
}

variable "lambda_function_pkg_file" {
  default = "../pkgs/zebrium_cloudwatch-1.0.zip"
}

variable "ze_deployment_name" {
  default = "<YOUR_DEPLOYMENT_NAME>"
}

variable "log_collector_url" {
  default = "<YOUR_ZE_API_URL>"
}

variable "log_collector_token" {
  default = "<YOUR_ZE_API_AUTH_TOKEN>"
}
