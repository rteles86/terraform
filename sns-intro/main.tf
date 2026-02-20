provider "aws" {
  region = "us-east-1"
}

// Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "lambda_zip_path" {
  description = "Path to the built lambda zip file (created by dotnet publish + zip)"
  type        = string
  default     = "./SendUpdateNotifications/SendUpdateNotifications.zip"
}

variable "role_name" {
  description = "IAM role name to use or create for the Lambda"
  type        = string
  default     = "send_update_notifications_lambda_role"
}

// IAM role for Lambda
// Check if the role already exists using an external helper script (returns {"exists":"true"} or {"exists":"false"})
data "external" "role_exists" {
  program = ["sh", "${path.module}/scripts/check_role.sh"]
  query = {
    role_name = var.role_name
  }
}

// If the role exists, fetch it. Use count so the data lookup only runs when the role exists.
data "aws_iam_role" "existing" {
  count = data.external.role_exists.result.exists == "true" ? 1 : 0
  name  = var.role_name
}

// Create the role only when it does not already exist.
resource "aws_iam_role" "lambda_role" {
  count = data.external.role_exists.result.exists == "true" ? 0 : 1

  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

// Inline policy: CloudWatch Logs + SNS Publish to the two topics
resource "aws_iam_role_policy" "lambda_policy" {
  name = "send_update_notifications_policy"
  role = length(data.aws_iam_role.existing) > 0 ? data.aws_iam_role.existing[0].id : aws_iam_role.lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = ["sns:Publish"],
        Resource = "*"
      }
    ]
  })
}

// Lambda function
resource "aws_lambda_function" "send_update_notifications" {
  function_name = "SendUpdateNotificatons"
  filename      = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  role = length(data.aws_iam_role.existing) > 0 ? data.aws_iam_role.existing[0].arn : aws_iam_role.lambda_role[0].arn
  handler       = "SendUpdateNotifications::SendUpdateNotifications.Function::FunctionHandler"
  runtime       = "dotnet8"
  memory_size   = 256
  timeout       = 30

  environment {
    variables = {
      USER_TOPIC_ARN     = "arn:aws:sqs:us-east-1:863207306552:user-updates-queue"
      PRODUCTS_TOPIC_ARN = "arn:aws:sqs:us-east-1:863207306552:product-updates-queue"
    }
  }
}

output "lambda_name" {
  value = aws_lambda_function.send_update_notifications.function_name
}

