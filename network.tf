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

module "sdwan_vpc" {
  for_each = toset(local.all_vpcs)
  source   = "terraform-google-modules/network/google"
  version  = "~> 5.0"

  project_id   = var.project_id
  network_name = "${each.value}-vpc"
  routing_mode = "GLOBAL"

  subnets = local.subnets[each.value]
}

module "inet_firewall_rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version      = "~> 5.0"
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
  version      = "~> 5.0"
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
