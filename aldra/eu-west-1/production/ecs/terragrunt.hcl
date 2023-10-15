terraform {
  source = "git@github.com:aldra-consulting/infrastructure-modules.git//packages/ecs?ref=ecs@0.5.0"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "cognito" {
  config_path = "../cognito"
}

dependency "dynamodb" {
  config_path = "../dynamodb"
}

dependency "secrets_manager" {
  config_path = "../secrets-manager"
}

dependency "ecr" {
  config_path = "../ecr"
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
    id                          = dependency.vpc.outputs.vpc_id
    private_subnets             = dependency.vpc.outputs.private_subnets
    private_subnets_cidr_blocks = dependency.vpc.outputs.private_subnets_cidr_blocks
  }

  services = [
    {
      name    = "auth-rest-api"
      ingress = "sidecar"
      port    = 8001
      cpu     = 512
      memory  = 1024
      container_definitions = {
        sidecar = {
          image                    = "${dependency.ecr.outputs.repository_url["auth-rest-api-sidecar"]}@${dependency.ecr.outputs.latest_image_tag_id["auth-rest-api-sidecar"]}"
          container_port           = 8001
          host_port                = 8001
          cpu                      = 256
          memory                   = 512
          readonly_root_filesystem = false
        }
        app = {
          image          = "${dependency.ecr.outputs.repository_url["auth-rest-api-app"]}@${dependency.ecr.outputs.latest_image_tag_id["auth-rest-api-app"]}"
          container_port = 8000
          host_port      = 8000
          cpu            = 256
          memory         = 512
          environment = {
            NODE_ENV                        = local.environment.name
            HOST                            = "0.0.0.0"
            PORT                            = "8000"
            ISSUER                          = "https://www.id.${local.environment.project.domain_name}"
            REALM                           = "aldra"
            AWS_REGION                      = local.region.name
            AWS_COGNITO_USER_POOL_ID        = dependency.cognito.outputs.user_pool_id
            AWS_COGNITO_USER_POOL_CLIENT_ID = dependency.cognito.outputs.user_pool_client_id
            AWS_SECRET_ARN_OIDC_COOKIE_KEYS = dependency.secrets_manager.outputs.secret_arn["oidc-cookie-keys"]
            AWS_SECRET_ARN_OIDC_JWKS        = dependency.secrets_manager.outputs.secret_arn["oidc-jwks"]
            OIDC_PROVIDER_DB_TABLE          = dependency.dynamodb.outputs.oidc_provider_dynamodb_table_id
            AUTH_INTERACTIONS_URL           = "https://www.id.${local.environment.project.domain_name}/interactions"
          }
        }
      }
      task_iam_policy_statements = {
        "dynamodb" = {
          effect = "Allow"
          actions = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem",
          ]
          resources = [
            dependency.dynamodb.outputs.oidc_provider_dynamodb_table_arn,
          ]
        }
        "secrets_manager" = {
          effect = "Allow"
          actions = [
            "secretsmanager:GetSecretValue",
          ]
          resources = [
            dependency.secrets_manager.outputs.secret_arn["oidc-cookie-keys"],
            dependency.secrets_manager.outputs.secret_arn["oidc-jwks"],
          ]
        }
        "cognito" = {
          effect = "Allow"
          actions = [
            "cognito-idp:AdminInitiateAuth",
            "cognito-idp:AdminGetUser",
          ]
          resources = [
            dependency.cognito.outputs.user_pool_arn,
          ]
        }
      }
    },
  ]
}
