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
  lan_vpc_valid = data.google_compute_network.lan-vpc.name == var.lan_vpc
  default_vpcs = ["mgmt", "inet"]
  create_vpcs = local.lan_vpc_valid == false ? concat(local.default_vpcs, ["lan"]) : local.default_vpcs
  all_vpcs = concat(local.default_vpcs, ["lan"])

  subnets = {
    inet = local.inet_subnets,
    mgmt = local.mgmt_subnets,
    lan  = local.lan_subnets
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

  lan_subnets = flatten([
      for network_region in var.network_regions : {
          subnet_name   = "lan-vpc-subnet-${network_region.name}"
          subnet_ip     = network_region.lan_subnet
          subnet_region = network_region.name
      }
  ])

  default_network_interfaces = {
    for key, vpc in module.sdwan_vpc : 
    key => {
      for region in var.network_regions : region.name => {
        network = vpc.network.network_self_link
        subnetwork = vpc.subnets["${region.name}/${vpc.network_name}-subnet-${region.name}"].self_link
        access_config = (key == "inet" ? [{}] : [] )
      }
    }
  }

  network_interfaces = merge({
    "lan" = local.lan_vpc_valid ? {
      for region in var.network_regions : region.name => {
        network    = data.google_compute_network.lan-vpc.self_link
        subnetwork = module.lan_subnets[0].subnets["${region.name}/lan-vpc-subnet-${region.name}"].self_link
      }
    } : {}
  }, local.default_network_interfaces)
 
}

data "google_compute_network" "lan-vpc" {
   name    = var.lan_vpc
   project = var.project_id
  # keeping this here, only support terraform 1.2
  # lifecycle {
  #   # The VPC name must match the var.lan_vpc variable
  #   postcondition {
  #     condition     = self.name == var.lan_vpc
  #     error_message = "Please provide a valid lan VPC name"
  #   }
  # }
}

module "sdwan_vpc" {
    for_each = toset(local.create_vpcs)
    source  = "terraform-google-modules/network/google"
    version = "~> 5.0"

    project_id   = var.project_id
    network_name = "${each.value}-vpc"
    routing_mode = "GLOBAL"

    subnets = local.subnets[each.value]
}

module "lan_subnets" {
  count  = local.lan_vpc_valid ? 1 : 0
  source = "terraform-google-modules/network/google//modules/subnets"
  version = "~> 5.0"

  project_id   = var.project_id
  network_name = data.google_compute_network.lan-vpc.name

  subnets = local.subnets["lan"]
}

data "velocloud_profile" "hub_profile" {
    name = "Hubs"
}

resource "velocloud_edge" "gcp_vce" {
  for_each     = {for region in var.network_regions: region.name => region}

  configurationid               = data.velocloud_profile.hub_profile.id
  modelnumber                   = "virtual"

  name                          = "${var.project_id}.sdwan-${each.value.name}"

  site {
    name                        = var.project_id
  }
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
    for_each = local.all_vpcs
    content {
      network = local.network_interfaces[network_interface.value][each.value.name].network
      subnetwork = local.network_interfaces[network_interface.value][each.value.name].subnetwork

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
