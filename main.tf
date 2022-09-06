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
  all_vpcs = ["mgmt", "inet", "lan"]
  regions = tolist([for region in var.network_regions: region.name])

  subnets = {
    for vpc in local.all_vpcs : vpc =>
      flatten([
      for network_region in var.network_regions : {
          subnet_name   = "${vpc}-vpc-subnet-${network_region.name}"
          subnet_ip     = network_region["${vpc}_subnet"]
          # subnet_ip     = lookup(network_region, "${vpc}_subnet")
          subnet_region = network_region.name
      }
      ])
  }

  network_interfaces = {
    for key, vpc in module.sdwan_vpc : 
    key => {
      for region in var.network_regions : region.name => {
        network = vpc.network.network_self_link
        subnetwork = vpc.subnets["${region.name}/${vpc.network_name}-subnet-${region.name}"].self_link
        access_config = (key == "inet" ? [{}] : [] )
        network_ip = (key == "lan" ? google_compute_address.lan_subnet_static_ip["${region.name}"].address : "" )
      }
    }
  } 
}

module "sdwan_vpc" {
    for_each = toset(local.all_vpcs)
    source  = "terraform-google-modules/network/google"
    version = "~> 5.0"

    project_id   = var.project_id
    network_name = "${each.value}-vpc"
    routing_mode = "GLOBAL"

    subnets = local.subnets[each.value]
}

module "inet_firewall_rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  project_id   = var.project_id
  network_name = module.sdwan_vpc["inet"].network_name

  rules = [{
    name                    = "inet-vpc-allow-vcmp-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "udp"
      ports    = ["2426"]
    }]
    deny = []
    log_config = {
      metadata = "EXCLUDE_ALL_METADATA"
    }
  }]
}

module "lan_firewall_rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  project_id   = var.project_id
  network_name = module.sdwan_vpc["lan"].network_name

  rules = [{
    name                    = "lan-vpc-allow-all-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "all"
      ports    = []
    }]
    deny = []
    log_config = {
      metadata = "EXCLUDE_ALL_METADATA"
    }
  }]
}

resource "google_compute_router" "lan_router" {
  for_each = toset([for region in var.network_regions: region.name])

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
        range = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description != "" ? advertised_ip_ranges.value.description : "Route for ${advertised_ip_ranges.value.range}"
      }
    }
  }
}

# need to use gcloud command to create nics since it's not supported by the provider
# feature request here: https://github.com/hashicorp/terraform-provider-google/issues/11206
module "router_nics" {
  for_each = {for region in var.network_regions: region.name => region}
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.0"

  platform = "linux"

  create_cmd_entrypoint = "${path.module}/scripts/gcloud_scripts.sh"
  create_cmd_body       = "add_router_nics sdwan-router-${each.value.name} ${cidrhost(each.value.lan_subnet, 10)} lan-vpc-subnet-${each.value.name} ${each.value.name} ${var.project_id}"

  depends_on = [
    google_compute_router.lan_router["*"],
    module.sdwan_vpc["*"]
  ]
}

data "velocloud_profile" "hub_profile" {
    name = var.velocloud_hub_profile
}

resource "google_compute_address" "lan_subnet_static_ip" {
  for_each     = {for region in var.network_regions: region.name => region}
  name         = "sdwan-${each.value.name}-lan-ip"
  subnetwork   = module.sdwan_vpc["lan"].subnets["${each.value.name}/${module.sdwan_vpc["lan"].network_name}-subnet-${each.value.name}"].self_link
  address_type = "INTERNAL"
  address      = cidrhost(each.value.lan_subnet, 2)
  region       = each.value.name
  project      = var.project_id
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

resource "velocloud_device_settings" "gcp_vce" {
  for_each = {for region in var.network_regions: region.name => region}
  profile  = velocloud_edge.gcp_vce[each.value.name].edgeprofileid

  vlan {
    cidr_ip = "192.168.100.1"
    advertise = false
    override = false
  }
  routed_interface {
    name            = "GE3"
    cidr_ip         = local.network_interfaces["lan"][each.value.name].network_ip
    cidr_prefix     = substr(each.value.lan_subnet, -2, -1)
    gateway         = cidrhost(each.value.lan_subnet, 1)
    netmask         = cidrnetmask(each.value.lan_subnet)
    type            = "STATIC"
  }

}

resource "google_compute_instance" "dm_gcp_vce" {
  for_each     = {for region in var.network_regions: region.name => region}
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
      network = local.network_interfaces[network_interface.value][each.value.name].network
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

resource "google_network_connectivity_hub" "basic_hub" {
  name        = "sdwanhub"
  description = "SDWAN hub"

  project = var.project_id
}

resource "google_network_connectivity_spoke" "primary" {
  for_each = {for region in var.network_regions: region.name => region}
  name = "sdwan-${each.value.name}"
  location = each.value.name
  description = "Spoke to the vce router appliance instance in ${each.value.name}"
  project = var.project_id

  hub =  google_network_connectivity_hub.basic_hub.id
  linked_router_appliance_instances {
    instances {
        virtual_machine = google_compute_instance.dm_gcp_vce[each.value.name].self_link
        ip_address = local.network_interfaces["lan"][each.value.name].network_ip
    }
    site_to_site_data_transfer = true
  }
}

module "bgp_peers" {
  for_each = {for region in var.network_regions: region.name => region}
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.0"

  platform = "linux"


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
