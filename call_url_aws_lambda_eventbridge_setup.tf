data "aws_lambda_function" "call_url" {
  function_name = "CallUrl"
}

data "aws_scheduler_schedule" "call_url_scheduler" {
  name = "CallUrlScheduler"
}

data "aws_sqs_queue" "call_url_dlq" {
  name = "CallUrlDLQ"
}

data "aws_iam_role" "pass_role_role" {
  name = "lambda_policy_passrole_CallUrl"
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name = "/aws/lambda/${data.aws_lambda_function.call_url.function_name}"
}

resource "aws_lambda_function" "call_url" {
  function_name    = "CallUrl"
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda_execution_role.arn
  filename         = "path/to/your/lambda/function.zip" # placeholder
  source_code_hash = filebase64sha256("path/to/your/lambda/function.zip") # placeholder
  depends_on = [aws_iam_role_policy_attachment.logging_attach, aws_iam_role_policy_attachment.eventbridge_attach, aws_iam_role_policy_attachment.passrole_attach]
}

resource "aws_scheduler_schedule" "call_url_scheduler" {
  name = "CallUrlScheduler"

  flexible_time_window {
    mode                   = "FLEXIBLE"
    maximum_window_in_minutes = 60
  }

  schedule_expression = "cron(0 9 ? * 2 *)"

  target {
    arn      = aws_lambda_function.call_url.arn
    role_arn = aws_iam_role.scheduler_execution_role.arn
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role_CallUrl"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_logging_policy" {
  name   = "lambda_logging_policy_CallUrl"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "logs:CreateLogGroup",
        Resource = aws_cloudwatch_log_group.lambda_logs.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "${aws_cloudwatch_log_group.lambda_logs.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy_eventbridge" {
  name   = "lambda_policy_eventbridge_CallUrl"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "scheduler:UpdateSchedule",
        Resource = data.aws_scheduler_schedule.call_url_scheduler.arn
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy_passrole" {
  name   = "lambda_policy_passrole_CallUrl"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "iam:PassRole",
        Resource = data.aws_iam_role.pass_role_role.arn
      }
    ]
  })
}

resource "aws_iam_role" "scheduler_execution_role" {
  name = "EventBridgeSchedulerExecutionRole"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "scheduler_policy" {
  name        = "EventBridgeSchedulerPolicy"
  description = "Policy for EventBridge Scheduler Execution Role"
  policy      = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Resource = [
          aws_lambda_function.call_url.arn,
          "${aws_lambda_function.call_url.arn}:*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["sqs:SendMessage"],
        Resource = [data.aws_sqs_queue.call_url_dlq.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "logging_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_role_policy_attachment" "eventbridge_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy_eventbridge.arn
}

resource "aws_iam_role_policy_attachment" "passrole_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy_passrole.arn
}

resource "aws_sqs_queue" "call_url_dlq" {
  name = "CallUrlDLQ"
}
