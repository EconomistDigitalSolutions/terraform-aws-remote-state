# Setup AWS provider
#
provider "aws" {
  region  = "${var.aws-region}"
  profile = "${var.aws-profile}"
}

# Create S3 bucket 
#   - enable versioning     (backups)
#   - apply policies        (security)
#   - apply encription      (security)
#   - apply prevent_destroy (robustness)
#
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.bucket_name}"
  policy = "${data.aws_iam_policy_document.iam_policy_document_s3.json}"

  versioning = {
    enabled = true
  }

  lifecycle = {
    prevent_destroy = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Add one file - not required - this is used to verify the policies work properly
#
# resource "aws_s3_bucket_object" "index_page" {
#   bucket       = "${aws_s3_bucket.s3_bucket.bucket}"
#   key          = "README.md"
#   source       = "README.md"
#   content_type = "text/html"
# }

# The DynamoDb table that locks the state file
#
resource "aws_dynamodb_table" "dynamodb_table" {
  name           = "${var.dynamodb_table_name}"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Create local variable for setting principals.identifiers
#
locals {
  accounts_arn = "${formatlist("arn:aws:iam::%s:root", var.list_account_ids)}"
}

# S3 policy 
#  - grant access to bucket and its files only 
#  - grant access to everyone in var.list_account_ids
#
data "aws_iam_policy_document" "iam_policy_document_s3" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.bucket_name}"]

    principals {
      type        = "AWS"
      identifiers = ["${local.accounts_arn}"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${local.accounts_arn}"]
    }
  }
}

# DynamoDB table policy 
#  - grant access table only
#  - grant access to everyone in var.list_account_ids
#
data "aws_iam_policy_document" "iam_policy_document_dynamodb" {
  statement {
    effect    = "Allow"
    resources = ["arn:aws:dynamodb:${var.aws-region}:${var.account_id}:table:${var.dynamodb_table_name}"]

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${local.accounts_arn}"]
    }
  }
}