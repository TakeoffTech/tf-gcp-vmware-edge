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
}

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

  network_interface {
    network    = module.mgmt_vpc.network_self_link
    subnetwork = module.mgmt_vpc.subnets["${each.value.name}/mgmt-vpc-subnet-${each.value.name}"].id
  }
  
  network_interface {
    network    = module.inet_vpc.network_self_link
    subnetwork = module.inet_vpc.subnets["${each.value.name}/inet-vpc-subnet-${each.value.name}"].id

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    user-data = templatefile("${path.module}/vce.userdata.tpl", {
      velocloud_vco              = "vco129-usvi1.velocloud.net"
      velocloud_activaction_code = "YPTF-PN33-THTX-28V5"
    })
  }

#   service_account {
#     # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
#     email  = google_service_account.default.email
#     scopes = ["cloud-platform"]
#   }
}