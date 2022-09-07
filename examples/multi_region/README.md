# Simple Example

This example illustrates how to use the `sdwan` module.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloud\_router\_advertised\_ip\_ranges | A List of additional ip ranges to advertise from the cloud router to the vce appliance | <pre>set(object(<br>    {<br>      range       = string<br>      description = string<br>    }<br>  ))</pre> | <pre>[<br>  {<br>    "description": "10.128 route",<br>    "range": "10.128.0.0/24"<br>  },<br>  {<br>    "description": "",<br>    "range": "10.254.0.0/16"<br>  }<br>]</pre> | no |
| network\_regions | List of regions and subnets to deploy VMware edge appliances | `list(map(string))` | <pre>[<br>  {<br>    "inet_subnet": "192.168.20.0/24",<br>    "lan_subnet": "10.0.10.0/24",<br>    "mgmt_subnet": "192.168.10.0/24",<br>    "name": "us-central1"<br>  },<br>  {<br>    "inet_subnet": "192.168.21.0/24",<br>    "lan_subnet": "10.0.11.0/24",<br>    "mgmt_subnet": "192.168.11.0/24",<br>    "name": "us-west2"<br>  }<br>]</pre> | no |
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |
| velocloud\_token | API Tokken for the Velocloud Orchestrator instance | `string` | n/a | yes |
| velocloud\_vco | Base hostname to the Velocloud Orchestrator instance | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| network\_regions | n/a |
| project\_id | The ID of the project in which to provision resources. |
| sdwan\_vpc | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

To provision this example, run the following from within this directory:
- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
- `terraform destroy` to destroy the built infrastructure
