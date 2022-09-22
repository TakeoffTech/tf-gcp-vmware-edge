// Copyright 2022 Takeoff Technologies Inc
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package multi_region

import (
	"fmt"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/stretchr/testify/assert"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestMultiRegionExample(t *testing.T) {
	multiRegion := tft.NewTFBlueprintTest(t)

	multiRegion.DefineVerify(func(assert *assert.Assertions) {
		//After adding service_account_key_file to the gcloud module
		//terraform apply is not idempotent 
		//multiRegion.DefaultVerify(assert)

		projectID := multiRegion.GetStringOutput("project_id")

		type Region struct {
			Name string
			Inet_subnet string
			Mgmt_subnet string
			Lan_subnet string
		  }
		var networkRegions []Region

		terraform.OutputStruct(t, multiRegion.GetTFOptions(), "network_regions", &networkRegions)

		services := gcloud.Run(t, "services list", gcloud.WithCommonArgs([]string{"--project", projectID, "--format", "json"})).Array()

		computeMatch := utils.GetFirstMatchResult(t, services, "config.name", "compute.googleapis.com")
		assert.Equal("ENABLED", computeMatch.Get("state").String(), "Compute service should be enabled")

		nccMatch := utils.GetFirstMatchResult(t, services, "config.name", "networkconnectivity.googleapis.com")
		assert.Equal("ENABLED", nccMatch.Get("state").String(), "Compute service should be enabled")

		// Validation VPCs, Subnets, and VM instances

		var vpcs = []string{
			"mgmt-vpc",
			"inet-vpc",
			"lan-vpc",
		}

		projectvpcs := gcloud.Run(t, fmt.Sprintf("compute networks list --project %s", projectID))
		subnets := gcloud.Run(t, fmt.Sprintf("compute networks subnets list --project %s", projectID))
		instances := gcloud.Run(t, fmt.Sprintf("compute instances list --project %s", projectID))

		for _, vpc := range vpcs {
			// validate VPCs are created
			assert.Equal(vpc, projectvpcs.Get("#(name=="+vpc+").name").String(), vpc+" VPC is created")

			for _, region := range networkRegions {
				//validate subnets in each regions
				subnetname := vpc + "-subnet-" + region.Name
				assert.Equal(subnetname, subnets.Get("#(name=="+subnetname+").name").String(), subnetname+" subnet is created")
			}
		}

		//Validate instances and attached networks the module manages
		for _, region := range networkRegions {
			instancename := "sdwan-" + region.Name

			//validate instance exsist
			assert.Equal(instancename, instances.Get("#(name=="+instancename+").name").String(), instancename+" vce appliance is created")
			for _, vpc := range vpcs {
				network := fmt.Sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/networks/%s", projectID, vpc)
				subnetwork := fmt.Sprintf("https://www.googleapis.com/compute/v1/projects/%s/regions/%s/subnetworks/%s-subnet-%s", projectID, region.Name, vpc, region.Name)

				//validate instance networking is connected to each vpc/subnet for the region
				assert.Equal(network, instances.Get("#(name=="+instancename+").networkInterfaces.#(network="+network+").network").String(), instancename+" has an interface on network "+network)
				assert.Equal(subnetwork, instances.Get("#(name=="+instancename+").networkInterfaces.#(network="+network+").subnetwork").String(), instancename+" has an interface on subnetwork "+subnetwork)
			}
		}

		//Validate instances and lan network attachment
		for _, region := range networkRegions {
			instancename := "sdwan-" + region.Name
			vpc := "lan-vpc"

			network := fmt.Sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/networks/%s", projectID, vpc)
			// subnetwork := fmt.Sprintf("https://www.googleapis.com/compute/v1/projects/%s/regions/%s/subnetworks/%s-subnet-%s", projectID, region["name"], vpc, region["name"])

			//validate instance networking is connected to each vpc/subnet for the region
			assert.Equal(network, instances.Get("#(name=="+instancename+").networkInterfaces.#(network="+network+").network").String(), instancename+" has an interface on network "+network)
			//assert.Equal(subnetwork, instances.Get("#(name==" + instancename + ").networkInterfaces.#(network=" + network + ").subnetwork").String(), instancename + " has an interface on subnetwork " + subnetwork )

		}

		//Validate NCC
		hubs := gcloud.Run(t, fmt.Sprintf("network-connectivity hubs list --project %s", projectID)).Array()
		spokes := gcloud.Run(t, fmt.Sprintf("network-connectivity spokes list --project %s", projectID)).Array()

		hubMatch := utils.GetFirstMatchResult(t, hubs, "name", fmt.Sprintf("projects/%s/locations/global/hubs/sdwanhub", projectID))
		assert.Equal("ACTIVE", hubMatch.Get("state").String(), "SDWAN Hub created")

		for _, region := range networkRegions {
			spokeMatch := utils.GetFirstMatchResult(t, spokes, "name", fmt.Sprintf("projects/%s/locations/%[2]s/spokes/sdwan-%[2]s", projectID, region.Name))
			assert.Equal("ACTIVE", spokeMatch.Get("state").String(), fmt.Sprintf("Spoke is active in %s", region.Name))
		}

		//Validate Cloud Routers
		routers := gcloud.Run(t, fmt.Sprintf("compute routers list --project %s", projectID))
		routerInterfaceNames := []string{"ra-1-0", "ra-1-1"}

		for _, region := range networkRegions {
			routerName := fmt.Sprintf("sdwan-router-%s", region.Name)
			routerInterfaces := routers.Get("#(name=="+routerName+").interfaces")
			bgpPeers := routers.Get("#(name=="+routerName+").bgpPeers")
			assert.Equal(routerName, routers.Get("#(name=="+routerName+").name").String(), fmt.Sprintf("Cloudrouter %s is created", routerName))

			//validate interfaces on the routers
			for _, routerInterfaceName := range routerInterfaceNames {
				assert.Equal(routerInterfaceName, routerInterfaces.Get("#(name=="+routerInterfaceName+").name").String(), routerInterfaceName + " Interface exists on " + routerName)

				//Validate BGPPeers
				bgpPeerName := routerInterfaceName + "-peer0"
				assert.Equal(bgpPeerName, bgpPeers.Get("#(name=="+bgpPeerName+").name").String(), bgpPeerName + " bgp peer exists on " + routerName)

			}
		}

	})
	multiRegion.Test()
}
