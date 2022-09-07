# tf-gcp-vmware-edge

This module was generated from [terraform-google-module-template](https://github.com/terraform-google-modules/terraform-google-module-template/), which by default generates a module that simply creates a GCS bucket. As the module develops, this README should be updated.

The resources/services/activations/deletions that this module will create/trigger are:

- Create a vmware edge deployment in your project
- You can specify what regions to deploy a single instance to

## Usage

Basic usage of this module is as follows:

```hcl
module "sdwan" {
  source  = "github.com/TakeoffTech/tf-gcp-vmware-edge"
  version = "~> 0.1"

  project_id  = "<PROJECT ID>"

  network_Regions = [
    {
      name        = "us-central1"
      inet_subnet = "192.168.20.0/24"
      mgmt_subnet = "192.168.10.0/24"
      lan_subnet  = "10.0.10.0/24"
    },
    {
      name        = "us-west2"
      inet_subnet = "192.168.21.0/24"
      mgmt_subnet = "192.168.11.0/24"
      lan_subnet  = "10.0.11.0/24"
    },
  ]

  velocloud_hub_profile = "Hub Profile"
  velocloud_vco = "vco123-usvi1.velocloud.net"
  # The velocloud_token passed in via the TF_VAR_velocloud_token environment variable
  velocloud_token = "Token"

}
```

Functional examples are included in the
[examples](./examples/) directory.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloud\_router\_advertised\_ip\_ranges | A List of additional ip ranges to advertise from the cloud router to the vce appliance | <pre>set(object(<br>    {<br>      range       = string<br>      description = string<br>    }<br>  ))</pre> | `[]` | no |
| cloud\_router\_asns | n/a | `list(number)` | <pre>[<br>  65120,<br>  65121,<br>  65122,<br>  65123<br>]</pre> | no |
| network\_regions | List of regions and subnets to deploy VMware edge appliances | <pre>set(object(<br>    {<br>      name        = string<br>      inet_subnet = string<br>      mgmt_subnet = string<br>      lan_subnet  = string<br>    }<br>  ))</pre> | `[]` | no |
| project\_id | The project ID to deploy to | `string` | n/a | yes |
| vce\_asns | n/a | `list(number)` | <pre>[<br>  65220,<br>  65221,<br>  65222,<br>  65223<br>]</pre> | no |
| vce\_machine\_type | GCP machine type for the Velocloud edge instance | `string` | `"n2-standard-4"` | no |
| velocloud\_hub\_profile | Name of a configuration profile to attach to the Veloloud edge instances | `string` | `"Hubs-Test"` | no |
| velocloud\_token | API token for the Velocloud Orchestrator instance | `string` | n/a | yes |
| velocloud\_vco | Base hostname to the Velocloud Orchestrator instance | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| inet\_subnets | n/a |
| lan\_subnets | n/a |
| mgmt\_subnets | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

These sections describe requirements for using this module.

### Software

The following dependencies must be available:

- [Terraform][terraform] v0.13
- [Terraform Provider for GCP][terraform-provider-gcp] plugin v4.0

### Service Account

A service account with the following roles must be used to provision
the resources of this module:

- Project Owner: `roles/owner`

The [Project Factory module][project-factory-module] and the
[IAM module][iam-module] may be used in combination to provision a
service account with the necessary roles applied.

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- Compute Engine API: `compute.googleapis.com`
- Network Connectivity API: `networkconnectivity.googleapis.com`

The [Project Factory module][project-factory-module] can be used to
provision a project with the necessary APIs enabled.

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

[iam-module]: https://registry.terraform.io/modules/terraform-google-modules/iam/google
[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html

## Security Disclosures

Please see our [security disclosure process](./SECURITY.md).
