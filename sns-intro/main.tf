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

provider "aws" {
  region = var.aws_region
}

// IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "send_update_notifications_lambda_role"

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
  role = aws_iam_role.lambda_role.id

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
  role          = aws_iam_role.lambda_role.arn
  handler       = "SendUpdateNotifications::SendUpdateNotifications.Function::FunctionHandler"
  runtime       = "dotnet9"
  memory_size   = 256
  timeout       = 30

  environment {
    variables = {
      USER_TOPIC_ARN     = arn:aws:sqs:us-east-1:863207306552:user-updates-queue
      PRODUCTS_TOPIC_ARN = arn:aws:sqs:us-east-1:863207306552:product-updates-queue
    }
  }
}

output "lambda_name" {
  value = aws_lambda_function.send_update_notifications.function_name
}

