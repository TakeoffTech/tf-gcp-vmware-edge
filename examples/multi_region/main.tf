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

module "sdwan" {
  source = "../.."

  project_id      = var.project_id
  network_regions = var.network_regions

  velocloud_vco   = var.velocloud_vco
  velocloud_token = var.velocloud_token

  cloud_router_advertised_ip_ranges = var.cloud_router_advertised_ip_ranges
}
