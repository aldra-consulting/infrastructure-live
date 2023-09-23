terraform {
  source = "git@github.com:aldra-consulting/infrastructure-modules.git//packages/dynamodb?ref=dynamodb@0.1.0"
}

include {
  path = find_in_parent_folders()
}

locals {
  common      = yamldecode(file(find_in_parent_folders("common.yml")))
  account     = yamldecode(file(find_in_parent_folders("account.yml")))
  region      = yamldecode(file(find_in_parent_folders("region.yml")))
  environment = yamldecode(file(find_in_parent_folders("environment.yml")))
  namespace   = "${local.common.project.name}-${local.region.name}-${local.environment.name}"
  tags        = merge(local.account.tags, local.region.tags, local.environment.tags)
}

inputs = {
  common      = local.common
  account     = local.account
  region      = local.region
  environment = local.environment
  namespace   = local.namespace
  tags        = local.tags
}
