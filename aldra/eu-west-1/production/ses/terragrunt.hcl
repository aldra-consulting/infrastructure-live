terraform {
  source = "git@github.com:finando/infrastructure-modules.git///packages/ses?ref=ses@0.3.0"
}

include {
  path = find_in_parent_folders()
}

locals {
  common      = yamldecode(file(find_in_parent_folders("common.yml")))
  account     = yamldecode(file(find_in_parent_folders("account.yml")))
  region      = yamldecode(file(find_in_parent_folders("region.yml")))
  environment = yamldecode(file(find_in_parent_folders("environment.yml")))
}

inputs = {
  common      = local.common
  account     = local.account
  region      = local.region
  environment = local.environment

  ssm_parameter_ses_configuration = "ses-configuration"
  ssm_parameter_ses_smtp_users    = "ses-smtp-users"
}
