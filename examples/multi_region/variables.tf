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

variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "network_regions" {
  description = "List of regions and subnets to deploy VMware edge appliances"
  type        = list(map(string))
  default = [
    {
      name = "us-central1"   
      inet_subnet = "192.168.20.0/24"
      mgmt_subnet = "192.168.10.0/24"
      lan_subnet  = "10.0.10.0/24"
    },
    {
      name = "us-west2"
      inet_subnet = "192.168.21.0/24"
      mgmt_subnet = "192.168.11.0/24"
      lan_subnet  = "10.0.11.0/24"
    },
  ]
}

variable "velocloud_vco" {
  description = "Base hostname to the Velocloud Orchestrator instance"
  type        = string 
}

variable "velocloud_token" {
  description = "API Tokken for the Velocloud Orchestrator instance"
  type        = string 
}