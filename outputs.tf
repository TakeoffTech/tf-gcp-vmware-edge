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

output "mgmt_subnets" {
  value       = module.sdwan_vpc["mgmt"].subnets
  description = "A map with keys of form subnet_region/subnet_name and values being the outputs of the google_compute_subnetwork resources used to create corresponding subnets within the mgmt VPC."
}

output "inet_subnets" {
  value       = module.sdwan_vpc["inet"].subnets
  description = "A map with keys of form subnet_region/subnet_name and values being the outputs of the google_compute_subnetwork resources used to create corresponding subnets within the inet VPC."
}

output "lan_subnets" {
  value       = module.sdwan_vpc["lan"].subnets
  description = "A map with keys of form subnet_region/subnet_name and values being the outputs of the google_compute_subnetwork resources used to create corresponding subnets within the lan VPC."
}

output "lan_self_link" {
  value       = module.sdwan_vpc["lan"].network_self_link
  description = "The URI of the lan VPC being created"
}

output "lan_network_id" {
  value       = module.sdwan_vpc["lan"].network_id
  description = "The ID of the lan VPC being created"
}
