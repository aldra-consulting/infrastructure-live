terraform {
  source = "git@github.com:aldra-consulting/infrastructure-modules.git//packages/route-53?ref=route-53@0.1.0"
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
}
