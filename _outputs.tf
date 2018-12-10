output "s3-bucket-domain-name" {
  description = "The state bucket domain name."
  value       = "${aws_s3_bucket.s3_bucket.bucket_domain_name}"
}

output "s3-bucket-id" {
  description = "The state bucket ID."
  value       = "${aws_s3_bucket.s3_bucket.id}"
}

output "dynamodb-table-id" {
  description = "The DynamoDB table ID."
  value       = "${aws_dynamodb_table.dynamodb_table.id}"
}
