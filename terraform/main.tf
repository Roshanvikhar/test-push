provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]
}

resource "aws_iam_role" "github_actions" {
  name = "GitHubActionsOIDCRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.github.arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:Roshanvikhar/test-push:*"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3_access" {
  name        = "GitHubActionsS3Policy"
  description = "Allow GitHub Actions to access S3"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:CreateBucket",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:PutBucketTagging"
        ],
        Resource = "arn:aws:s3:::my-github-actions-bucket"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:*"],
        Resource = "arn:aws:s3:::my-github-actions-bucket/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_s3_bucket" "github_bucket" {
  bucket = "my-github-actions-bucket"
}