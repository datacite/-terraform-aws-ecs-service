provider "aws" {
  region = "eu-west-1"
}

module "ecs-service" {
    source = "../../"

    app_name = "hello-world"
    env = "test"
    lb_name = "lb"
    vpc_id = "test_vpc"
    subnet_ids = ["test_subnet123"]
    security_group_ids = ["test_sg123"]
    namespace_id = "test_namespace"
    desired_container_count = 1
    setup_alb = true
    dns_record_name = "example.com"
}