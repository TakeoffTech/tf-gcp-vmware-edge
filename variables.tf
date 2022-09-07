/**
 * Copyright 2021 Takeoff Technologies Inc
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

variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "network_regions" {
  description = "List of regions and subnets to deploy VMware edge appliances"
  type = set(object(
    {
      name        = string
      inet_subnet = string
      mgmt_subnet = string
      lan_subnet  = string
    }
  ))
  default = []
}

variable "cloud_router_asns" {
  type    = list(number)
  default = [65120, 65121, 65122, 65123]
}

variable "vce_asns" {
  type    = list(number)
  default = [65220, 65221, 65222, 65223]
}

variable "vce_machine_type" {
  description = "GCP machine type for the Velocloud edge instance"
  type        = string
  default     = "n2-standard-4"

}

variable "velocloud_vco" {
  description = "Base hostname to the Velocloud Orchestrator instance"
  type        = string
}

variable "velocloud_token" {
  description = "API token for the Velocloud Orchestrator instance"
  type        = string
}

variable "velocloud_hub_profile" {
  description = "Name of a configuration profile to attach to the Veloloud edge instances"
  type        = string
  default     = "Hubs-Test"
}

variable "cloud_router_advertised_ip_ranges" {
  description = "A List of additional advertised ip ranges from the cloud router to the vce appliance"
  type = set(object(
    {
      range       = string
      description = string
    }
  ))
  default = []
}