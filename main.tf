locals {
  # Filters policies by type (`SERVICE_CONTROL_POLICY`)
  policy_filter = "SERVICE_CONTROL_POLICY"
  # Path to the JSON file defining the organization units
  org_units_path = "${path.module}/organization-units.json"

  # Decoded JSON content from the `org_units_path` file
  org_units = jsondecode(file(local.org_units_path))

  # Root OU Policies
  root_ou_policies = ["root_policy_1", "root_policy_2"]

  #  A flattened list of OUs and their respective policies
  ous_policy = flatten([
    for organization_unit in local.org_units : [
      for policy in organization_unit.policies : {
        name   = organization_unit.name
        policy = policy
    }]
  ])

  # The root ID of the AWS Organization
  root_id = data.aws_organizations_organization.org.roots[0].id

  # Maps Root child OUs by name to their IDs
  map_children_ous = {
    for key, val in data.aws_organizations_organizational_unit_descendant_organizational_units.ous.children
    : val.name => val.id
  }

  # Maps policy names to their IDs
  map_policies = {
    for key, val in data.aws_organizations_policy.policies : val.name => val.policy_id
  }

  # Combines root and child OUs into a unified map
  root_children_ous = merge(local.map_children_ous, { Root = local.root_id })
}

# Fetches organization details
data "aws_organizations_organization" "org" {}

# Fetches descendant OUs from the root
data "aws_organizations_organizational_unit_descendant_organizational_units" "ous" {
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

# Fetches policies based on the filter
data "aws_organizations_policies" "org" {
  filter = local.policy_filter
}

# Fetches individual policy details
data "aws_organizations_policy" "policies" {
  for_each  = toset(data.aws_organizations_policies.org.ids)
  policy_id = each.value
}

# Creates OUs dynamically based on the provided JSON file
resource "aws_organizations_organizational_unit" "ous" {
  for_each = {
    for ou in local.org_units : ou.name => ou
    # Make sure the Parent OU exists
    if contains(keys(local.root_children_ous), ou.parent_name)
  }

  name      = each.value.name
  tags      = each.value.tags
  parent_id = local.root_children_ous[each.value.parent_name]
}

# Attaches policies to the respective OUs based on the provided JSON file
resource "aws_organizations_policy_attachment" "ou_policy_attachment" {
  for_each = {
    for oup in local.ous_policy : "${oup.name}_${oup.policy}" => oup
    # Make sure the OU exist before attaching Policy
    if contains(keys(aws_organizations_organizational_unit.ous), oup.name)
  }

  target_id = aws_organizations_organizational_unit.ous[each.value.name].id
  policy_id = local.map_policies[each.value.policy]
}

# Attaches policies to Root OU
resource "aws_organizations_policy_attachment" "root_ou_policy_attachment" {
  for_each = {
    for idx, policy in local.root_ou_policies : "root_${policy}" => policy
  }

  target_id = local.root_id
  policy_id = local.map_policies[each.value]
}
