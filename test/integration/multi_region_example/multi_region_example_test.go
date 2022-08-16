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

package multiple_buckets

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

		mgmtvpc := gcloud.Run(t, fmt.Sprintf("compute networks describe sdwan-mgmt-vpc --project %s", projectID))
		assert.Equal("sdwan-mgmt-vpc", mgmtvpc.Get("name").String(), "sdwan-mgmt-vpc VPC is created")

		inetvpc := gcloud.Run(t, fmt.Sprintf("compute networks describe sdwan-inet-vpc --project %s", projectID))
		assert.Equal("sdwan-inet-vpc", inetvpc.Get("name").String(), "sdwan-inet-vpc VPC is created")

		// networkregions := default2.GetStringOutput("network_regions")
		// subnets := gcloud.Run(t, fmt.Sprintf("compute networks subnets list --project %s", projectID))

		// result := networkregions.Get(json, "#.name")
		// for _, name := range result.Array() {
		// 	println(name.String())
		// }
		// regionNames := []string{default2.GetStringOutput("network_regions")}
		// println(regionNames)

		// assert.Equal("us-central1-inet-vpc-subnet", subnets.Get("name").String(), "us-central1-inet-vpc-subnet subnet is created")
		// assert.Equal("us-central1-mgmt-vpc-subnet", subnets.Get("name").String(), "us-central1-mgmt-vpc-subnet subnet is created")
		// assert.Equal("us-west2-inet-vpc-subnet", subnets.Get("name").String(), "us-west2-inet-vpc-subnet subnet is created")
		// assert.Equal("us-west2-mgmt-vpc-subnet", subnets.Get("name").String(), "us-west2-mgmt-vpc-subnet subnet is created")

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

