module "lan_vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 5.0"

    project_id   = var.project_id
    network_name = "lan-vpc"
    routing_mode = "GLOBAL"

    subnets = [{
        subnet_name   = "lan-vpc-subnet-1"
        subnet_ip     = "10.128.0.0/24"
        subnet_region = "us-central1"
    },{
        subnet_name   = "lan-vpc-subnet-2"
        subnet_ip     = "10.129.0.0/24"
        subnet_region = "us-west2"
    }]
}


module "multi-region-fixture" {
 // setup the source for the fixture as the example for the test
 source              = "../../../examples/multi_region"
 // set variables as required by the example module
 project_id          = var.project_id
 lan_vpc             = module.lan_vpc.network_name
}