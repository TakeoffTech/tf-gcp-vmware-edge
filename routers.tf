/**
 * Copyright 2022 Takeoff Technologies Inc
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_compute_router" "lan_router" {
  for_each = toset([for region in var.network_regions : region.name])

  name    = "sdwan-router-${each.value}"
  project = var.project_id
  region  = each.value
  network = module.sdwan_vpc["lan"].network_self_link
  bgp {
    asn               = var.cloud_router_asns[index(local.regions, each.value)]
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    dynamic "advertised_ip_ranges" {
      for_each = var.cloud_router_advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description != "" ? advertised_ip_ranges.value.description : "Route for ${advertised_ip_ranges.value.range}"
      }
    }
  }
}

# get GOOGLE_APPLICATION_CREDENTIALS for below commands
data "external" "env" {
  program = ["${path.module}/scripts/env.sh"]
}

# need to use gcloud command to create nics since it's not supported by the provider
# feature request here: https://github.com/hashicorp/terraform-provider-google/issues/11206
module "router_nics" {
  for_each = { for region in var.network_regions : region.name => region }
  source   = "terraform-google-modules/gcloud/google"
  version  = "~> 3.0"

  platform = "linux"

  service_account_key_file = data.external.env.result["google_application_credentials"]

  create_cmd_entrypoint  = "${path.module}/scripts/gcloud_scripts.sh"
  create_cmd_body        = "add_router_nics sdwan-router-${each.value.name} ${cidrhost(each.value.lan_subnet, 10)} lan-vpc-subnet-${each.value.name} ${each.value.name} ${var.project_id}"

  depends_on = [
    google_compute_router.lan_router["*"],
    module.sdwan_vpc["*"]
  ]
}

# Setup BGP sessions on the routers
module "bgp_peers" {
  for_each = { for region in var.network_regions : region.name => region }
  source   = "terraform-google-modules/gcloud/google"
  version  = "~> 3.0"

  platform = "linux"

  service_account_key_file = data.external.env.result["google_application_credentials"]

  create_cmd_entrypoint = "${path.module}/scripts/gcloud_scripts.sh"
  create_cmd_body       = "add-bgp-peers sdwan-router-${each.value.name} ${cidrhost(each.value.lan_subnet, 2)} ${var.vce_asns[index(local.regions, each.value.name)]} ${google_compute_instance.dm_gcp_vce[each.value.name].self_link} ${each.value.name} ${var.project_id}"

  destroy_cmd_entrypoint = "${path.module}/scripts/gcloud_scripts.sh"
  destroy_cmd_body       = "remove-bgp-peers sdwan-router-${each.value.name} ${each.value.name} ${var.project_id}"

  depends_on = [
    google_compute_instance.dm_gcp_vce["*"],
    module.router_nics["*"].wait,
    google_network_connectivity_spoke.primary["*"]
  ]
}
