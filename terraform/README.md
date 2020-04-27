# ZEBRIUM CLOUDWATCH LAMBDA FUNCTION DEPLOYMENT WITH TERRAFORM
This directory contains terraform configurations for creating AWS lambda
function and configuring AWS CloudWatch log group to stream logs to
Zebrium API server. 

# How to use
1. Edit variable.tf file, replace all user specific settings (all the settings in capital letter) with real settings.
2. Initialize terraform:
   * `terraform init`
3. Import existing cloudwatch log group:
   * `terraform import aws_cloudwatch_log_group.test_group <NAME_OF_YOUR_EXISTING_LOG_GROUP>`
4. Run command to create all resources and set up streaming from log group to lambda function:
   * `terraform apply`
