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

resource "google_network_connectivity_hub" "basic_hub" {
  name        = "sdwanhub"
  description = "SDWAN hub"

  project = var.project_id
}

resource "google_network_connectivity_spoke" "primary" {
  for_each    = { for region in var.network_regions : region.name => region }
  name        = "sdwan-${each.value.name}"
  location    = each.value.name
  description = "Spoke to the vce router appliance instance in ${each.value.name}"
  project     = var.project_id

  hub = google_network_connectivity_hub.basic_hub.id
  linked_router_appliance_instances {
    instances {
      virtual_machine = google_compute_instance.dm_gcp_vce[each.value.name].self_link
      ip_address      = local.network_interfaces["lan"][each.value.name].network_ip
    }
    site_to_site_data_transfer = true
  }
}
