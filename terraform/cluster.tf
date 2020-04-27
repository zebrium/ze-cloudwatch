provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  region     = var.region
}

resource "aws_cloudwatch_log_group" "test_group" {
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "${var.lambda_function_pkg_file}"
  function_name = "${var.lambda_function_name}"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "index.handler"

  source_code_hash = "${filebase64sha256("${var.lambda_function_pkg_file}")}"
  runtime = "nodejs12.x"

  environment {
    variables = {
      ZE_DEPLOYMENT_NAME = "${var.ze_deployment_name}"
      ZE_LOG_COLLECTOR_URL = "${var.log_collector_url}"
      ZE_LOG_COLLECTOR_TOKEN = "${var.log_collector_token}"
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.test_lambda.function_name}"
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.test_group.arn}"
# qualifier     = "${aws_lambda_alias.test_alias.name}"
}

resource "aws_lambda_alias" "test_alias" {
  name             = "testalias"
  description      = "a sample description"
  function_name    = "${aws_lambda_function.test_lambda.function_name}"
  function_version = "$LATEST"
}

resource "aws_cloudwatch_log_subscription_filter" "test_lambdafunction_logfilter" {
  name            = "test_lambdafunction_logfilter"
  #role_arn        = "${aws_iam_role.iam_for_lambda.arn}"
  log_group_name  = "${aws_cloudwatch_log_group.test_group.name}"
  filter_pattern  = ""
  destination_arn = "${aws_lambda_function.test_lambda.arn}"
  depends_on      = ["aws_lambda_permission.allow_cloudwatch"]
}
