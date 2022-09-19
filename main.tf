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

locals {
  all_vpcs = ["mgmt", "inet", "lan"]
  regions  = tolist([for region in var.network_regions : region.name])

  subnets = {
    for vpc in local.all_vpcs : vpc =>
    flatten([
      for network_region in var.network_regions : {
        subnet_name   = "${vpc}-vpc-subnet-${network_region.name}"
        subnet_ip     = network_region["${vpc}_subnet"]
        subnet_region = network_region.name
      }
    ])
  }

  network_interfaces = {
    for key, vpc in module.sdwan_vpc :
    key => {
      for region in var.network_regions : region.name => {
        network       = vpc.network.network_self_link
        subnetwork    = vpc.subnets["${region.name}/${vpc.network_name}-subnet-${region.name}"].self_link
        access_config = (key == "inet" ? [{}] : [])
        network_ip    = (key == "lan" ? google_compute_address.lan_subnet_static_ip["${region.name}"].address : "")
      }
    }
  }
}
