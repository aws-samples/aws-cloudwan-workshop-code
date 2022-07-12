# AWS Cloud WAN - Infrastructure as Code Examples

AWS Cloud WAN is a managed wide-area networking (WAN) service that you can use to build, manage, and monitor an unified global network that connects resources running across your cloud and on-premises environments. It provides a central dashboard from which you can connect on-premises branch offices, data centers, and Amazon Virtual Private Clouds (VPCs) across the AWS global network. You can use simple network policies to centrally configure and automate network management and security tasks, and get a complete view of your global network.

This repository shows you an example of global communication with AWS Cloud WAN, showing the same architecture you can build in the [AWS Cloud WAN Workshop](https://catalog.workshops.aws/cloudwan/en-US) using different Infrastructure as Code (IaC) frameworks: CloudFormation, CDK (with Typescript and Python examples) and Terraform.

![architecture diagram](images/cloud_wan_architecture.png "AWS Cloud WAN diagram")

* [AWS CloudFormation](./cloudformation/)
* [AWS CDK (Typescript)](./cdk_typescript/)
* [AWS CDK (Python)](./cdk_python/)
* [Terraform](./terraform/)

**NOTE**: The resources created incur costs in your AWS Account. Consider deleting the resources created once your tests are done. For more information, check the [AWS Cloud WAN pricing](https://aws.amazon.com/cloud-wan/pricing/).

## References

* [AWS Cloud WAN documentation](https://docs.aws.amazon.com/vpc/latest/cloudwan/what-is-cloudwan.html).
* [AWS Cloud WAN Workshop](https://catalog.workshops.aws/cloudwan/en-US).
* Blog post: [Introducing AWS Cloud WAN (Preview)](https://aws.amazon.com/blogs/networking-and-content-delivery/introducing-aws-cloud-wan-preview/).

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
