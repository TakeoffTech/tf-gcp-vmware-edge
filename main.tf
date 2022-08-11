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

module "mgmt-vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 5.0"

    project_id   = var.project_id
    network_name = "sdwan-mgmt-vpc"
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name           = "${var.regions[0]}-subnet"
            subnet_ip             = "192.168.10.0/24"
            subnet_region         = var.regions[0]
        }
    #    },
    #     {
    #         subnet_name           = "${var.regions[1]}-subnet"
    #         subnet_ip             = "192.168.11.0/24"
    #         subnet_region         = var.regions[1]
    #     }
    # ]

    # routes = [
    #     {
    #         name                   = "egress-internet"
    #         description            = "route through IGW to access internet"
    #         destination_range      = "0.0.0.0/0"
    #         tags                   = "egress-inet"
    #         next_hop_internet      = "true"
    #     },
    #     {
    #         name                   = "app-proxy"
    #         description            = "route through proxy to reach app"
    #         destination_range      = "10.50.10.0/24"
    #         tags                   = "app-proxy"
    #         next_hop_instance      = "app-proxy-instance"
    #         next_hop_instance_zone = "us-west1-a"
    #     },
    ]
}

module "inet-vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 5.0"

    project_id   = var.project_id
    network_name = "sdwan-inet-vpc"
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name           = "${var.regions[0]}-subnet"
            subnet_ip             = "192.168.20.0/24"
            subnet_region         = var.regions[0]
        }
    #    },
    #     {
    #         subnet_name           = "${var.regions[1]}-subnet"
    #         subnet_ip             = "192.168.21.0/24"
    #         subnet_region         = var.regions[1]
    #     }
    # ]

    # routes = [
    #     {
    #         name                   = "egress-internet"
    #         description            = "route through IGW to access internet"
    #         destination_range      = "0.0.0.0/0"
    #         tags                   = "egress-inet"
    #         next_hop_internet      = "true"
    #     },
    #     {
    #         name                   = "app-proxy"
    #         description            = "route through proxy to reach app"
    #         destination_range      = "10.50.10.0/24"
    #         tags                   = "app-proxy"
    #         next_hop_instance      = "app-proxy-instance"
    #         next_hop_instance_zone = "us-west1-a"
    #     },
    ]
}