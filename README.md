# Terraform AWS Organization Structure Management

This Terraform module manages the structure and policies attached to the AWS Organizations Units (OUs).

Features:

- Dynamically creates Organizations Units within AWS Organizations based on a JSON configuration file.
- Automatically attaches specified policies to the created OUs.
- Supports hierarchical OU creation with parent-child relationships.

## organization-units.json

```json
[
  {
    "name": "Engineering",
    "parent_name": "Root",
    "tags": { "Environment": "Production" },
    "policies": ["PolicyA"]
  },
  {
    "name": "DevOps",
    "parent_name": "Engineering",
    "tags": { "Team": "Support" },
    "policies": ["PolicyB"]
  }
  ...
]
```

## Prerequisites

1. **Terraform Version**: Terraform 1.8.
2. **S3 backend bucket**: S3 backend bucket and update `backend.config` file.
3. **Policy Configuration**: Pre-Define policies
4. **Organizational Units JSON File**: Create a `organization-units.json` file to define the structure of your OUs.

## Example Workflow

1. Set AWS environment/profile for example by running `export AWS_REGION="eu-west-2"` and `export AWS_PROFILE=Your_Profile`
2. Run `terraform init -backend-config=./backend.config` to initialize the module.
3. Execute plan `terraform plan -lock=false` to preview changes.
4. Apply the configuration `terraform apply -lock=false`.
5. If necessary, re-run point 3 and 4 for nested OUs. Nested OUs depend on parent IDs, which may not be available in the first Terraform `apply`.
