# AWS Cloud WAN - CloudFormation

AWS Cloud WAN is a managed wide-area networking (WAN) service that you can use to build, manage, and monitor an unified global network that connects resources running across your cloud and on-premises environments. It provides a central dashboard from which you can connect on-premises branch offices, data centers, and Amazon Virtual Private Clouds (VPCs) across the AWS global network. You can use simple network policies to centrally configure and automate network management and security tasks, and get a complete view of your global network.

This repository shows you an example in AWS CloudFormation of global communication with AWS Cloud WAN, showing the same architecture you can build in the [AWS Cloud WAN Workshop](https://catalog.workshops.aws/cloudwan/en-US).

![architecture diagram](../images/cloud\_wan\_architecture.png "AWS Cloud WAN diagram")

**NOTE**: The resources created incur costs in your AWS Account. Consider deleting the resources created once your tests are done. For more information, check the [AWS Cloud WAN pricing](https://aws.amazon.com/cloud-wan/pricing/).

## Deployment instructions

This sample project is meant to be deployed to a single account and multiple regions. By default, AWS regions **us-east-1** and **eu-west-1** are in use.

* `make deploy` will deploy all three stacks (core network, us-east-1 VPC, eu-west-1 VPC)
* `make undeploy` will delete all three stacks
* If you make updates to the environment, you can run `make deploy` again safely to update
* To deploy or undeploy an individual stack, use the targets `deploy-core`, `deploy-virginia` and `deploy-ireland` (and `undeploy-` for each too)
