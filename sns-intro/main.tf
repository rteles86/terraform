provider "aws" {
  region = "us-east-1"
}

resource "aws_sns_topic" "my-first-sns" {
  name = "my-first-sns"
}
