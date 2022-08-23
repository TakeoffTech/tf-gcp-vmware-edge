variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "lan_vpc" {
  description = "Name or self_link of exsisiting VPC for the lan side of the appliance"
  type        = string
}

locals {
  default_vpcs = ["mgmt", "inet"]
  all_vpcs = data.google_compute_network.lan-vpc.name == var.lan_vpc ? concat(local.default_vpcs, ["lan"]) : local.default_vpcs
}

data "google_compute_network" "lan-vpc" {
   name    = var.lan_vpc
   project = var.project_id
  lifecycle {
    # The VPC name must match the var.lan_vpc variable
    postcondition {
      condition     = self.name == var.lan_vpc
      error_message = "Please provide a valid lan VPC name"
    }
  }
}

# data "external" "throw_error" {
#     count = data.google_compute_network.lan-vpc.name == var.lan_vpc ? 0 : 1
#     program = ["echo", "{['Please provide a valid lan VPC name']}"]
# }

# resource "null_resource" "validate_lan_vpc_lookup" {
#   count = data.google_compute_network.lan-vpc.name == var.lan_vpc ? 0 : "Please provide a valid lan VPC name"
# }

# resource "null_resource" "all_is_good" {
# depends_on = [
#   null_resource.validate_lan_vpc_lookup
# ]
# }


output "lan-vpc" {
  value = data.google_compute_network.lan-vpc
}

output "all-vpcs" {
  value = local.all_vpcs
}