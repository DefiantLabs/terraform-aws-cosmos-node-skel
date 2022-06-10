# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "../../../../../modules/github.com/terraform-aws-modules/terraform-aws-transit-gateway"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  # account_vars = read_terragrunt_config( "/home/dan/code/gitlab.ai-labs.cloud/altitudeDevelopment/deploy-tool/Terraform/live/dbryan/us-east-1/altitude-dev-dbryan-CommonServices/account.hcl")

  # Extract the variables we need for easy access
  account_id   = local.account_vars.locals.aws_account_id
  account_name = local.account_vars.locals.account_name
  aws_profile  = local.account_vars.locals.aws_profile
}

dependency "CommonServices_aws_vpc" {
  config_path = "../../CommonServices/aws_vpc"
}

dependency "SecurityServices_aws_vpc" {
  config_path = "../../SecurityServices/aws_vpc"
}

dependency "Governance_aws_vpc" {
  config_path = "../../Governance/aws_vpc"
}


# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  name = "altitude--${local.account_name}-tgw"
  description     = "My TGW shared with several other AWS accounts"
  amazon_side_asn = 64532

  enable_auto_accept_shared_attachments = true // When "true" there is no need for RAM resources if using multiple AWS accounts

  vpc_attachments = {
    commonservices = {
      vpc_id                                          = dependency.CommonServices_aws_vpc.outputs.vpc_id      # module.vpc1.vpc_id
      subnet_ids                                      = dependency.CommonServices_aws_vpc.outputs.private_subnets  # module.vpc1.private_subnets
      dns_support                                     = true
      transit_gateway_default_route_table_association = true
      transit_gateway_default_route_table_propagation = true
      //      transit_gateway_route_table_id = "tgw-rtb-073a181ee589b360f"

      tgw_routes = [
        {
          destination_cidr_block = dependency.CommonServices_aws_vpc.outputs.vpc_cidr_block
        },
        {
          destination_cidr_block = "0.0.0.0/0"
        }
      ]
    },
  }

  ram_allow_external_principals = true
  ram_principals                = [dependency.SecurityServices_aws_vpc.outputs.vpc_owner_id, dependency.Governance_aws_vpc.outputs.vpc_owner_id]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
  # TODO: To avoid storing your DB password in the code, set it as the environment variable TF_VAR_master_password
}
