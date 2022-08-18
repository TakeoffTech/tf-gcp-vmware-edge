// Copyright 2022 Google LLC
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
)

func TestMultiRegionExample(t *testing.T) {
	multiRegion := tft.NewTFBlueprintTest(t)

	multiRegion.DefineVerify(func(assert *assert.Assertions) {
		multiRegion.DefaultVerify(assert)

		projectID := multiRegion.GetStringOutput("project_id")
		services := gcloud.Run(t, "services list", gcloud.WithCommonArgs([]string{"--project", projectID, "--format", "json"})).Array()

		match := utils.GetFirstMatchResult(t, services, "config.name", "compute.googleapis.com")
		assert.Equal("ENABLED", match.Get("state").String(), "storage service should be enabled")

		// Validation VPCs, Subnets, and VM instances

		var vpcs = []string{
			"mgmt-vpc", 
			"inet-vpc",
		}

		var network_regions = []map[string]string{
				{
					"name": "us-central1",
					"inet_subnet": "192.168.20.0/24",
					"mgmt_subnet": "192.168.10.0/24",
				},
				{
					"name": "us-west2",
					"inet_subnet": "192.168.21.0/24",
					"mgmt_subnet": "192.168.11.0/24",
				},
			}
			
		projectvpcs := gcloud.Run(t, fmt.Sprintf("compute networks list --project %s", projectID))
		subnets := gcloud.Run(t, fmt.Sprintf("compute networks subnets list --project %s", projectID))
		instances := gcloud.Run(t, fmt.Sprintf("compute instances list --project %s", projectID))

		for _, vpc := range vpcs {
			// validate VPCs are created 
			vpcname := "sdwan-" + vpc
			assert.Equal(vpcname, projectvpcs.Get("#(name==" + vpcname + ").name").String(), vpcname + " VPC is created")
			
			for _, region := range network_regions {
				//validate subnets in each regions 
				subnetname := vpc + "-subnet-" + region["name"]
				assert.Equal(subnetname, subnets.Get("#(name==" + subnetname + ").name").String(), subnetname + " subnet is created")
			}
		}

		//Validate instances and network
			for _, region := range network_regions {
				// subnetname := vpc + "-subnet-" + region["name"]
				instancename := "sdwan-" + region["name"]

				//validate instance exsist 
				assert.Equal(instancename, instances.Get("#(name==" + instancename + ").name").String(), instancename + " vce appliance is created")
				// for _, vpc := range vpcs {
				// 	vpcname := "sdwan-" + vpc

				// 	//validate instance networking is connected to each vpc/subnet for the region
				// 	assert.Equal(instancename, instances.Get("#(name==" + instancename + ").name").String(), instancename + " vce appliance is created")
				// }
			}


	})
	multiRegion.Test()
}

// func VPCNetworksTest(t *testing.T) {
// 	vpc := tft.NewTFBlueprintTest(t)

// 	vpc.DefineVerify(func(assert *assert.Assertions) {
// 		vpc.DefaultVerify(assert)

// 		projectID := vpc.GetStringOutput("project_id")
// 		op := gcloud.Run(t, fmt.Sprintf("compute networks describe sdwan-mgmt-vpc --project %s", projectID))

// 		// match := utils.GetFirstMatchResult(t, sdwanMgmtVpc, "name", "sdwan-mgmt-vpc")
// 		// assert.Equal("ENABLED", match.Get("state").String(), "storage service should be enabled")
// 		assert.Equal("sdwan-mgmt-vpc", op.Get("name"), "sdwan-mgmt-vpc VPC is created")
// 	})
// 	vpc.Test()
// }
