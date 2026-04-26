variable "db_username" {
  description = "The username for the database"
  type        = string
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "key_pair_name" {
  description = "The name of the AWS key pair to use for the EC2 instance"
  type        = string
}

variable "kaggle_username" { 
  type = string 
}
variable "kaggle_key" { 
  type      = string
  sensitive = true 
}

variable "terraform_state_bucket" {
  description = "The name of the S3 bucket to store Terraform state"
  type        = string
  sensitive = true
}