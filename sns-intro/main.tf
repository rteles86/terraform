resource "aws_sns_topic" "notification_updates" {
  name = "user-updates-topic"
}

resource "aws_sqs_queue" "user_updates_queue" {
  name   = "user-updates-queue"
  policy = data.aws_iam_policy_document.sqs_queue_policy.json
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.notification_updates.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.user_updates_queue.arn
}

resource "aws_sqs_queue" "product_updates_queue" {
  name   = "product-updates-queue"
  policy = data.aws_iam_policy_document.sqs_queue_policy.json
}

resource "aws_sns_topic_subscription" "product_updates_sqs_target" {
  topic_arn = aws_sns_topic.notification_updates.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.product_updates_queue.arn
}

data "aws_iam_policy_document" "sqs_queue_policy" {
  policy_id = "terraform-sns-sqs"

  statement {
    sid    = "user_updates_sqs_target"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    "Action": [
        "sqs:*"
    ],
    "Effect": "Allow",
    "Resource": "*"
  }
}