# CLOUDWATCH COLLECTOR DETAILS
Zebrium's CloudWatch collector (lambda function for AWS) sends logs to Zebrium for automated Anomaly detection.
Our github repository is located [here](https://github.com/zebrium/ze-cloudwatch).

# ze-cloudwatch

## Getting Started
### Preparation
1. Download Zebrium CloudWatch Lambda function package from https://github.com/zebrium/ze-cloudwatch/raw/master/pkgs/zebrium_cloudwatch-1.0.zip
2. If you have an existing Lambda function associated with the log group to be set up, you must go to AWS CloudWatch page and delete the existing subscription filter, otherwise you will get this error message: "An error occurred when creating the trigger: The log group host-log already has an enabled subscription filter associated with it."
3. If you do not have an existing role with Lambda execution permission, you should got to AWS IAM service to create a role for running Lambda functions.

### Installation
1. Create a new Lambda function
    1. Go to [AWS Lambda page](https://us-west-2.console.aws.amazon.com/lambda)
    2. Select "Author from scratch"
    3. Provide the following base information:
        * Function Name: zebrium-cloudwatch
        * Runtime: Node.js.12.x
    4. Click on "Create function"
2. Edit function details
    1. On "Code entry type" dropdown menu, choose "Upload a .zip file"
    2. Upload the Zebrium Lambda function package file you just downloaded
    3. Enter "index.handler" for Handler setting
    4. Choose "Node.js.12.x" for Runtime
    5. For Execution role, choose an existing role with Lambda execution permission
    6. Click on Designer and click on "Add a trigger". Type "CloudWatch Logs" and choose your log group.
    7. Set the following environment variables:
        * `ZE_DEPLOYMENT_NAME`: Deployment name (Required)
        * `ZE_HOST`: Alternative Host Name (Optional)
        * `ZE_LOG_COLLECTOR_URL`: ZAPI URL
        * `ZE_LOG_COLLECTOR_TOKEN`: Auth token

Click on Save button to save your new Lambda function. New logs should appear on Zebrium web portal in a couple of minutes.

## Configuration
No additional configuration is required

### Setup
No additional setup is required

## Testing your installation
Once the collector has been deployed in your CloudWatch environment, your logs and anomaly detection will be available in the Zebrium UI.

## Contributors
* Brady Zuo (Zebrium)
