terraform {
  source = "git@github.com:aldra-consulting/infrastructure-modules.git//packages/cloudfront?ref=cloudfront@0.2.0"
}

dependency "api_gateway" {
  config_path = "../api-gateway"
}

dependency "s3" {
  config_path = "../../..//global/production/s3"
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

  cloudfront_distributions = [
    {
      name        = "root"
      domain_name = local.environment.project.domain_name
      cache_behaviours = [
        {
          path             = "/build/*"
          type             = "S3"
          target_origin_id = dependency.s3.outputs.s3_bucket_id["landing-page-web"]
        },
        {
          type                = "S3"
          disable_cache       = true
          rewrite_request_url = true
          target_origin_id    = dependency.s3.outputs.s3_bucket_id["landing-page-web"]
        },
      ]
      s3_origins = [
        {
          id            = dependency.s3.outputs.s3_bucket_id["landing-page-web"]
          domain_name   = dependency.s3.outputs.s3_bucket_regional_domain_name["landing-page-web"]
          s3_bucket_id  = dependency.s3.outputs.s3_bucket_id["landing-page-web"]
          s3_bucket_arn = dependency.s3.outputs.s3_bucket_arn["landing-page-web"]
        },
      ]
      custom_error_response = [
        {
          error_code         = 404
          response_code      = 200
          response_page_path = "/redirect.html"
        },
        {
          error_code         = 403
          response_code      = 200
          response_page_path = "/redirect.html"
        }
      ]
    },
    {
      name        = "id"
      domain_name = "id.${local.environment.project.domain_name}"
      cache_behaviours = [
        {
          type             = "API_GATEWAY"
          target_origin_id = "id-api-gateway"
        },
        {
          path             = "/interactions/build/*"
          type             = "S3"
          target_origin_id = dependency.s3.outputs.s3_bucket_id["sso-web"]
        },
        {
          path                = "/interactions/*"
          type                = "S3"
          disable_cache       = true
          rewrite_request_url = true
          target_origin_id    = dependency.s3.outputs.s3_bucket_id["sso-web"]
        },
        {
          path                = "/interactions"
          type                = "S3"
          disable_cache       = true
          rewrite_request_url = true
          target_origin_id    = dependency.s3.outputs.s3_bucket_id["sso-web"]
        },
      ]
      api_gateway_origins = [
        {
          id          = "id-api-gateway"
          domain_name = replace(dependency.api_gateway.outputs.api_gateway_api_endpoint["id-api-gateway"], "/^https?://([^/]*).*/", "$1")
        },
      ]
      s3_origins = [
        {
          id            = dependency.s3.outputs.s3_bucket_id["sso-web"]
          domain_name   = dependency.s3.outputs.s3_bucket_regional_domain_name["sso-web"]
          s3_bucket_id  = dependency.s3.outputs.s3_bucket_id["sso-web"]
          s3_bucket_arn = dependency.s3.outputs.s3_bucket_arn["sso-web"]
        },
      ]
      custom_error_response = [
        {
          error_code         = 404
          response_code      = 200
          response_page_path = "/interactions/redirect.html"
        },
        {
          error_code         = 403
          response_code      = 200
          response_page_path = "/interactions/redirect.html"
        }
      ]
    },
  ]
}
