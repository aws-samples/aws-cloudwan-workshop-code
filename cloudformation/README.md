# AWS Cloud WAN - CloudFormation

AWS Cloud WAN is a managed wide-area networking (WAN) service that you can use to build, manage, and monitor an unified global network that connects resources running across your cloud and on-premises environments. It provides a central dashboard from which you can connect on-premises branch offices, data centers, and Amazon Virtual Private Clouds (VPCs) across the AWS global network. You can use simple network policies to centrally configure and automate network management and security tasks, and get a complete view of your global network.

This repository shows you an example in AWS CloudFormation of global communication with AWS Cloud WAN, showing the same architecture you can build in the [AWS Cloud WAN Workshop](https://catalog.workshops.aws/cloudwan/en-US).

![architecture diagram](../images/cloud\_wan\_architecture.png "AWS Cloud WAN diagram")

**NOTE**: The resources created incur costs in your AWS Account. Consider deleting the resources created once your tests are done. For more information, check the [AWS Cloud WAN pricing](https://aws.amazon.com/cloud-wan/pricing/).

## Deployment instructions

This sample project is meant to be deployed to a single account and multiple regions. By default, AWS regions **us-west-1** and **eu-north-1** are in use.

* `make deploy` will deploy all four stacks (core network, workloads, inspection, and legacy). However, the static routes in the Core Network policy will require for you to make to different deployments.
  * First, in *CoreNetwork.yaml* **uncomment lines 55 - 93, and 108 - 113** and use `make deploy`. This will deploy all the resources except the static routes pointing to the Inspection VPC attachments.
  * After this, **uncomment lines 94 - 107** and use `make update-cloudwan`. This will finish the deployment.
* `make undeploy` will delete all four stacks

## Following the lab instructions

* To follow the workshop, you can either use the AWS Management console as indicated in the workshop instructions, or follow the instructions below to deploy the resources in the same order.
* To build the inital architecture before starting the lab instructions, use `make deploy-initial`.

### Lab 1 - Build a global, segmented network with central egress

* Step 1 - *Create/Review JSON for Core Network Policy*. Nothing to do here, everything is built with the first deployment.
* Step 2 - *Update Core Network Policy*. This section updates the Core Network policy with the *attachment_policies*. In *CoreNetwork.yaml* **uncomment lines 60-81**, and use `make deploy-cloudwan` to update the Core Network policy.
* Step 3 - *Create attachments*. This section attaches the Spoke and Inspection VPCs to the Core Network. Use `make deploy-vpc-attachments` to create the Cloud WAN VPC attachments.
* Step 4 - *Update Core Network Policy for routing*. Now we are adding more information to the Core Network policy, related to the routing from the Spoke VPCs to the Inspection VPCs. Use `make update-cloudwan` to update the Core Network policy.
  * In *CoreNetwork.yaml*, **uncomment lines 89 to 107**.
  * Note that the Attachment IDs of the Inspection VPCs (both Regions) are retrieved and passed to the CloudFormation parameters information in the *Makefile* definition.
* Step 5 - *Update VPC Route tables*. Configuring the VPC routes to point to the Core Network attachment (in all VPCs in both Regions). Use `make deploy-vpc-routes` to create the VPC routes.
* Step 6 - *Perform tests to validate configuration*. Nothing to do here, follow the lab instructions.

### Lab 2 - Federate with AWS Transit Gateway

* Step 1 - *Core Policy Updates*. We need to update the Core Network policy to include the "legacy" infrastructure (TGW and Legacy VPC). In *CoreNetwork,yaml*, **uncomment lines 55 - 59, 82 - 88, and 108 - 113**. Use `make deploy-cloudwan`
* Step 2 - *TGW Peering*. Create TGW peering to Cloud WAN in both Regions. Use `make deploy-peering` to deploy the peerings.
* Step 3 - *TGW Attachments*. Create the TGW route table attachments in Cloud WAN (in both Regions). Use `make deploy-tgwrt-attachments` to deploy the Cloud WAN attachments.
* Step 4 - *Update VPC and TGW Route Tables*. In this section, we have to create the VPC routing in the Legacy VPCs to communicate to the Transit Gateway. Use `make deploy-legacy-routes` to create the VPC routes.
* Step 5 - *Validation*. Nothing to do here, follow the lab instructions.

**NOTE**: Remember to do `make undeploy` when you are done with the lab and your tests, to avoid undesired charges.

## References

* [AWS Cloud WAN documentation](https://docs.aws.amazon.com/vpc/latest/cloudwan/what-is-cloudwan.html).
* [AWS Cloud WAN Workshop](https://catalog.workshops.aws/cloudwan/en-US).
* Blog post: [Introducing AWS Cloud WAN (Preview)](https://aws.amazon.com/blogs/networking-and-content-delivery/introducing-aws-cloud-wan-preview/).
* Blog post: [AWS Cloud WAN and AWS Transit Gateway migration and interoperability patterns](https://aws.amazon.com/blogs/networking-and-content-delivery/aws-cloud-wan-and-aws-transit-gateway-migration-and-interoperability-patterns/)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.