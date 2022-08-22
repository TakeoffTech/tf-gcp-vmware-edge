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
  network_interfaces = {
    mgmt = {
      us-central1 = {
        network    = module.mgmt_vpc.network_self_link
        subnetwork = module.mgmt_vpc.subnets["us-central1/mgmt-vpc-subnet-us-central1"].id
      },
      us-west2 = {
        network    = module.mgmt_vpc.network_self_link
        subnetwork = module.mgmt_vpc.subnets["us-west2/mgmt-vpc-subnet-us-west2"].id
      },
    },
    inet = {
      us-central1 = {
        network    = module.inet_vpc.network_self_link
        subnetwork = module.inet_vpc.subnets["us-central1/inet-vpc-subnet-us-central1"].id
        access_config = [{}]
      },
      us-west2 = {
        network    = module.inet_vpc.network_self_link
        subnetwork = module.inet_vpc.subnets["us-west2/inet-vpc-subnet-us-west2"].id
        access_config = [{}]
      }
    }

  }
}

data "google_compute_network" "lan-vpc" {
   name    = var.lan_vpc
   project = var.project_id
}

# module "sdwan_vpc" {
#     for_each = toset(["mgmt", "inet"])
#     source  = "terraform-google-modules/network/google"
#     version = "~> 5.0"

#     project_id   = var.project_id
#     network_name = "sdwan-${each.name}-vpc"
#     routing_mode = "GLOBAL"
#     dynamic "subnets" {
#       for_each = {for region in var.network_regions: region.name => region}
#       content {
#         subnet_name = "${each.name}-vpc-subnet-${subnets.value["name"]}"
#         subnet_ip     = subnets.value["${each.name}_subnet"]
#         subnet_region = subnets.value["name"]
#       }
#     }
# }

module "mgmt_vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 5.0"

    project_id   = var.project_id
    network_name = "sdwan-mgmt-vpc"
    routing_mode = "GLOBAL"

    subnets = local.mgmt_subnets

}

module "inet_vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 5.0"

    project_id   = var.project_id
    network_name = "sdwan-inet-vpc"
    routing_mode = "GLOBAL"

    subnets = local.inet_subnets

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
    for_each = toset(["inet", "mgmt"])
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
      velocloud_vco              = "vco129-usvi1.velocloud.net"
      velocloud_activaction_code = "YPTF-PN33-THTX-28V5"
    })
  }

}