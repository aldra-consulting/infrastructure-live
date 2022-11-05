remote_state {
  backend = "s3"

  config = {
    encrypt        = true
    bucket         = "aldra-consulting-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "aldra-consulting-terraform-locks"
    profile        = "terragrunt@aldra-consulting"
  }
}
