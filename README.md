# Calling a URL intermittently from AWS

## Licensing

This project is licensed under the [GNU General Public License v3.0](LICENSE).

## Description

This repository provides the code to call some URLs intermittently from AWS, with the purpose of mocking user traffic to those URLs in a simplistic manner. All code, documents, files, etc. in this repository were created for the sole purpose of experimenting with AWS and are provided as is for educative purposes only.

Code: [index.mjs](index.mjs)  
AWS infrastructure: [Terraform](call_url_aws_lambda_eventbridge_setup.tf).

There is an AWS EventBridge Schedule which triggers an AWS Lambda function on a schedule. When the Lambda function is triggered, it randomly chooses one of the defined URLs and then calls it. The Lambda function then randomly chooses a point of time within the next two days that a URL should be called again. It then updates the original EventBridge Schedule to reflect that. In other words, the Lambda function is modifying the schedule of its own execution.

The [test.mjs](test.mjs) file can be used for testing and debugging the code locally.

The Terraform defines all the AWS resources required. It has not been thoroughly tested and some modifications may be necessary to use it.

Several resources are defined:
- AWS Lambda function
- AWS EventBridge Schedule
- AWS SQS - to be used by the schedule as a DLQ
- IAM execution role for the AWS EventBridge Schedule. The schedule needs to be able to send messages to the DLQ and trigger the Lambda function
- IAM role for the AWS Lambda function. The Lambda function needs to be able to write logs, update the schedule, and pass the execution role to the schedule

### Advantages of using AWS Lambda
- low resource usage, low cost
- it is likely that each execution will have a different IP address, which may be useful for simulating random traffic to the URLs

## Further improvements

It should be easier to configure the expected number of times the Lambda function runs per month. Currently, the next execution time is some time within the following two days. This amounts to roughly 45 function executions per month. This number should be directly configurable and the code should do the rest.

Also, monitoring would be nice.
