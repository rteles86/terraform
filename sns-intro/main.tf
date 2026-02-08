provider "aws" {
  region = "us-east-1"
}

# SNS Topic
resource "aws_sns_topic" "notification_updates" {
  name = "notification_updates-topic"
}

# SQS Queue - User Updates
resource "aws_sqs_queue" "user_updates_queue" {
  name = "user-updates-queue"
}

# Policy para User Updates Queue
data "aws_iam_policy_document" "user_updates_queue_policy" {
  statement {
    sid    = "Allow-SNS-SendMessage-UserUpdates"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.user_updates_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.notification_updates.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "user_updates_queue_policy_attachment" {
  queue_url = aws_sqs_queue.user_updates_queue.id
  policy    = data.aws_iam_policy_document.user_updates_queue_policy.json
}

# Subscription SNS -> SQS (User Updates)
resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.notification_updates.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.user_updates_queue.arn
}

# SQS Queue - Product Updates
resource "aws_sqs_queue" "product_updates_queue" {
  name = "product-updates-queue"
}

# Policy para Product Updates Queue
data "aws_iam_policy_document" "product_updates_queue_policy" {
  statement {
    sid    = "Allow-SNS-SendMessage-ProductUpdates"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.product_updates_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.notification_updates.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "product_updates_queue_policy_attachment" {
  queue_url = aws_sqs_queue.product_updates_queue.id
  policy    = data.aws_iam_policy_document.product_updates_queue_policy.json
}

# Subscription SNS -> SQS (Product Updates)
resource "aws_sns_topic_subscription" "product_updates_sqs_target" {
  topic_arn = aws_sns_topic.notification_updates.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.product_updates_queue.arn
}

# Bucket S3
resource "aws_s3_bucket" "notifications" {
  bucket = "notifications"
  acl    = "private"

  tags = {
    Name        = "notifications"
    Environment = "dev"
  }
}

# Criar "pasta" users
resource "aws_s3_object" "users_folder" {
  bucket = aws_s3_bucket.notifications.id
  key    = "users/"   # prefixo que simula pasta
}

# Criar "pasta" products
resource "aws_s3_object" "products_folder" {
  bucket = aws_s3_bucket.notifications.id
  key    = "products/"
}
