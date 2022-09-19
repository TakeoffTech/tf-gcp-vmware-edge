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

data "velocloud_profile" "hub_profile" {
  name = var.velocloud_hub_profile
}

resource "google_compute_address" "lan_subnet_static_ip" {
  for_each     = { for region in var.network_regions : region.name => region }
  name         = "sdwan-${each.value.name}-lan-ip"
  subnetwork   = module.sdwan_vpc["lan"].subnets["${each.value.name}/${module.sdwan_vpc["lan"].network_name}-subnet-${each.value.name}"].self_link
  address_type = "INTERNAL"
  address      = cidrhost(each.value.lan_subnet, 2)
  region       = each.value.name
  project      = var.project_id
}

resource "velocloud_edge" "gcp_vce" {
  for_each        = { for region in var.network_regions : region.name => region }
  configurationid = data.velocloud_profile.hub_profile.id
  modelnumber     = "virtual"
  name            = "${var.project_id}.sdwan-${each.value.name}"
  site {
    name = var.project_id
  }
}

resource "velocloud_device_settings" "gcp_vce" {
  for_each = { for region in var.network_regions : region.name => region }
  profile  = velocloud_edge.gcp_vce[each.value.name].edgeprofileid

  vlan {
    cidr_ip   = "192.168.100.1"
    advertise = false
    override  = false
  }
  routed_interface {
    name        = "GE3"
    cidr_ip     = local.network_interfaces["lan"][each.value.name].network_ip
    cidr_prefix = substr(each.value.lan_subnet, -2, -1)
    gateway     = cidrhost(each.value.lan_subnet, 1)
    netmask     = cidrnetmask(each.value.lan_subnet)
    type        = "STATIC"
  }
}

resource "time_sleep" "wait_300_seconds" {
  depends_on = [velocloud_edge.gcp_vce["*"]]

  destroy_duration = "300s"
}

resource "google_compute_instance" "dm_gcp_vce" {
  for_each     = { for region in var.network_regions : region.name => region }
  depends_on   = [time_sleep.wait_300_seconds]
  name         = "sdwan-${each.value.name}"
  machine_type = var.vce_machine_type
  zone         = "${each.value.name}-a"
  project      = var.project_id

  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = "projects/vmware-sdwan-public/global/images/vce-342-102-r342-20200610-ga-3f5ad3b9e2"
    }
  }

  dynamic "network_interface" {
    for_each = local.all_vpcs
    content {
      network    = local.network_interfaces[network_interface.value][each.value.name].network
      subnetwork = local.network_interfaces[network_interface.value][each.value.name].subnetwork
      network_ip = local.network_interfaces[network_interface.value][each.value.name].network_ip

      dynamic "access_config" {
        for_each = try(local.network_interfaces[network_interface.value][each.value.name].access_config, [])
        content {
        }
      }
    }
  }
  metadata = {
    user-data = templatefile("${path.module}/vce.userdata.tpl", {
      velocloud_vco              = var.velocloud_vco
      velocloud_activaction_code = velocloud_edge.gcp_vce[each.value.name].activationkey
    })
  }
}
