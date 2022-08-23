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

# output "bucket_name" {
#   value = google_storage_bucket.main.name
# }

output "sdwan_vpc" {
  value = "sdwan_vpc"
  # value = local.network_interfaces
  # value = local.all_vpcs
  # value = [for vpc in module.sdwan_vpc : vpc.network_name ]
  # value = [for key, vpc in module.sdwan_vpc : key ]
  # value = module.sdwan_vpc
  # value = module.lan_subnets
  # value = toset([for region in var.network_regions: region.name])
}

output "mgmt_subnets" {
  value = module.sdwan_vpc["mgmt"].subnets
}

output "inet_subnets" {
  value = module.sdwan_vpc["inet"].subnets
}