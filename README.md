# ze-cloudwatch

## Preparation

1. Download Zebrium CloudWatch Lamda function package from https://github.com/zebrium/ze-cloudwatch/raw/master/pkgs/zebrium_cloudwatch-1.0.zip
2. If you have an existing Lambda function associated with the log group to be set up, you must go to AWS CloudWatch page and delete the existing subscription filter, otherwise you will get this error message: "An error occurred when creating the trigger: The log group host-log already has an enabled subscription filter associated with it."
3. If you do not have an existing role with Lambda execution permission, you should got to AWS IAM service to create a role for running Lambda functions.

## Installation
2. Create a new Lambda function
  1. Go to [AWS Ldmba page](https://us-west-2.console.aws.amazon.com/lambda)
  2. Select "Author from scratch"
  3. Provide the following base information:
   * Function Name: zebrium-cloudwatch
   * Runtime: Node.js.12.x
  4. Click on "Create function"
3. Edit function details
  1. On "Code entry type" dropdown menu, choose "Upload a .zip file"
  2. Upload the Zebrium Lambda function package file you just downloaded
  3. Enter "index.handler" for Handler setting
  4. Choose "Node.js.12.x" for Runtime
  5. For Execution role, choose an existing role with Lambda excution permission
  6. Click on Designer and click on "Add a trigger". Type "CloudWatch Logs" and choose your log group.
  7. Set the following environment variables:
   * ZE_DEPLOYMENT_NAME: Deployment name (Required)
   * ZE_HOST: Alternative Host Name (Optional)
   * ZE_LOG_COLLECTOR_URL: ZAPI URL
   * ZE_LOG_COLLECTOR_TOKEN: Auth token
   
Click on Save button to save your new Lambda function. New logs should appear on Zebrium web portal in a coulple of minutes.
