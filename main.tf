/**
 * Copyright 2021 Google LLC
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

locals {
  default_vpcs = ["mgmt", "inet"]
  all_vpcs = data.google_compute_network.lan-vpc.name == var.lan_vpc ? concat(local.default_vpcs, ["lan"]) : local.default_vpcs

  subnets = {
    inet = local.inet_subnets,
    mgmt = local.mgmt_subnets
  }

  mgmt_subnets = flatten([
      for network_region in var.network_regions : {
          subnet_name   = "mgmt-vpc-subnet-${network_region.name}"
          subnet_ip     = network_region.mgmt_subnet
          subnet_region = network_region.name
      }
  ])

  inet_subnets = flatten([
      for network_region in var.network_regions : {
          subnet_name   = "inet-vpc-subnet-${network_region.name}"
          subnet_ip     = network_region.inet_subnet
          subnet_region = network_region.name
      }
  ])

  # network_interfaces = {
  #   for vpc in module.sdwan_vpc : 
  #   vpc.key => {
  #     for region in var.network_regions : region.name => {
  #       network = module.sdwan_vpc[(vpc)].network_self_link
  #       #subnetwork = module.sdwan_vpc["mgmt"].subnets["${region.name}/${vpc}-vpc-subnet-${region.name}"].id
  #       subnetwork = module.sdwan_vpc["mgmt"].subnets["us-central1/${vpc}-vpc-subnet-us-central1"].id
  #       access_config = (vpc == "inet" ? [{}] : null )
  #     } 
  #   } 
  # }

  default_network_interfaces = {
    for key, vpc in module.sdwan_vpc : 
    key => {
      for region in var.network_regions : region.name => {
        network = vpc.network.network_self_link
        subnetwork = vpc.subnets["${region.name}/${vpc.network_name}-subnet-${region.name}"].self_link
        access_config = (vpc == "inet" ? [{}] : null )
      }
    }
  }

  network_interfaces = loacl.default_network_interfaces

  # network_interfaces = merge(local.default_network_interfaces, {
  #   var.vpc_name = {
  #     network    = data.google_compute_network.lan_vpc.self_link
  #     subnetwork = () 
  #   }
  # })
 
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

module "sdwan_vpc" {
    for_each = toset(local.default_vpcs)
    source  = "terraform-google-modules/network/google"
    version = "~> 5.0"

    project_id   = var.project_id
    network_name = "${each.value}-vpc"
    routing_mode = "GLOBAL"

    subnets = local.subnets[each.value]
}

resource "google_compute_instance" "dm_gcp_vce" {
  for_each     = {for region in var.network_regions: region.name => region}
  name         = "sdwan-${each.value.name}"
  machine_type = "n2-standard-4"
  zone         = "${each.value.name}-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "projects/vmware-sdwan-public/global/images/vce-342-102-r342-20200610-ga-3f5ad3b9e2"
    }
  }

  dynamic "network_interface" {
    for_each = local.default_vpcs
    content {
      network = local.network_interfaces[network_interface.value][each.value.name].network
      subnetwork = local.network_interfaces[network_interface.value][each.value.name].subnetwork

      dynamic "access_config" {
        for_each = try(local.network_interfaces[network_interface][each.value.name].access_config, [])
        content {
        }
      }
    }
  }
  metadata = {
    user-data = templatefile("${path.module}/vce.userdata.tpl", {
      velocloud_vco              = "vco129-usvi1.velocloud.net"
      velocloud_activaction_code = "YPTF-PN33-THTX-28V5"
    })
  }
}
