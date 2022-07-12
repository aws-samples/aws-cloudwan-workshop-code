# AWS Cloud WAN - CloudFormation

AWS Cloud WAN is a managed wide-area networking (WAN) service that you can use to build, manage, and monitor an unified global network that connects resources running across your cloud and on-premises environments. It provides a central dashboard from which you can connect on-premises branch offices, data centers, and Amazon Virtual Private Clouds (VPCs) across the AWS global network. You can use simple network policies to centrally configure and automate network management and security tasks, and get a complete view of your global network.

This repository shows you an example in AWS CloudFormation of global communication with AWS Cloud WAN, showing the same architecture you can build in the [AWS Cloud WAN Workshop](https://catalog.workshops.aws/cloudwan/en-US).

![architecture diagram](../images/cloud\_wan\_architecture.png "AWS Cloud WAN diagram")

**NOTE**: The resources created incur costs in your AWS Account. Consider deleting the resources created once your tests are done. For more information, check the [AWS Cloud WAN pricing](https://aws.amazon.com/cloud-wan/pricing/).

## Deployment instructions

Currently, the CloudFormation example consists on a single file: *CoreNetwork.yaml*. This file only deploys the Global Network and Core Network (with the same policy is used in other examples). We are currently working in providing the full architecture, so stay tuned!
