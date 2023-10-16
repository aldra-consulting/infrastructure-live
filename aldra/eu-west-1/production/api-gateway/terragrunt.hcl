terraform {
  source = "git@github.com:aldra-consulting/infrastructure-modules.git//packages/api-gateway?ref=api-gateway@0.1.0"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "ecs" {
  config_path = "../ecs"
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

  vpc = {
    id              = dependency.vpc.outputs.vpc_id
    private_subnets = dependency.vpc.outputs.private_subnets
  }

  api_gateways = [
    {
      name        = "id-api-gateway"
      domain_name = "id.${local.environment.project.domain_name}"
      integrations = {
        "$default" = {
          connection_type    = "VPC_LINK"
          vpc_link           = "auth-rest-api-vpc-link"
          integration_uri    = dependency.ecs.outputs.load_balancer_https_listener_arns["auth-rest-api"][0]
          integration_type   = "HTTP_PROXY"
          integration_method = "ANY"
          tls_config = jsonencode({
            server_name_to_verify = "id.${local.environment.project.domain_name}"
          })
        }
      }
    },
  ]
}
