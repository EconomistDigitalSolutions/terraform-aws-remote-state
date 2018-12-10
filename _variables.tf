variable "aws-profile" {
  type        = "string"
  description = "The AWS profile name."
}

variable "bucket_name" {
  type        = "string"
  description = "The name for the bucket where the remote state is saved."
}

variable "dynamodb_table_name" {
  type        = "string"
  description = "The name of the DynamoDb table used to lock the state."
}

variable "list_account_ids" {
  type        = "list"
  description = "A list containing IDs of account that may access the state."
}

variable "account_id" {
  type        = "string"
  description = "The ID number of the account to where the state is being deployed."
}

variable "remote_state_file_name" {
  type        = "string"
  description = "The name for the file where the remote state is saved"
  default     = "state_terraform"
}

variable "aws-region" {
  type        = "string"
  description = "The AWS region where the terraform stack is created"
  default     = "eu-west-1"
}
