# AWS Cloud WAN - CloudFormation

AWS Cloud WAN is a managed wide-area networking (WAN) service that you can use to build, manage, and monitor an unified global network that connects resources running across your cloud and on-premises environments. It provides a central dashboard from which you can connect on-premises branch offices, data centers, and Amazon Virtual Private Clouds (VPCs) across the AWS global network. You can use simple network policies to centrally configure and automate network management and security tasks, and get a complete view of your global network.

This repository shows you an example in AWS CloudFormation of global communication with AWS Cloud WAN, showing the same architecture you can build in the [AWS Cloud WAN Workshop](https://catalog.workshops.aws/cloudwan/en-US).

![architecture diagram](../images/cloudwan_workshop_architecture.png "AWS Cloud WAN diagram")

**NOTE**: The resources created incur costs in your AWS Account. Consider deleting the resources created once your tests are done. For more information, check the [AWS Cloud WAN pricing](https://aws.amazon.com/cloud-wan/pricing/).

## Deployment instructions

* Clone the repository
* If you want to follow the [workshop instructions](https://catalog.workshops.aws/cloudwan/en-US), move to the [Following the lab instructions](#following-the-lab-instructions) section.
* If you want to test out the code outside the lab instructions, check carefully each stack and the resources it deploys:
  * `Workloads.yaml` creates the spoke VPCs.
  * `Inspection.yaml` creates both Inspection VPCs (egress and east-west).
  * `Legacy.yaml` creates the legacy infrastructure with Transit Gateway.
  * `OnPremises.yaml` creates the *mock on-premises* in eu-west-2 (London).
  * `VPN.yaml` creates the VPN connection resources.

## Following the lab instructions

**NOTE**: The final state of both workshop labs is codified in this repository. However, some pieces are commented or only deployed if specific parameters are configured. Check below to understand how to deploy the environment for each different state.

### Lab 1 - Build a global, segmented network with central egress

1. If you want to follow the lab guide:
  * `make deploy-initial` to build the initial environment.
2. If you want to build the end architecture after finishing the steps:
  * Uncomment lines 54-80 and 90-114 in `CoreNetwork.yaml`.
  * Execute `make deploy-lab1`.

Use `make undeploy` to clean-up the test environment and avoid undesired charges.

### Lab 2 - Federate with AWS Transit Gateway

1. If you want to follow the lab guide:
  * Check point 2 in [Lab 1](#lab-1---build-a-global-segmented-network-with-central-egress) to uncomment the corresponding lines and do `make deploy-lab1` to build the initial environment.
  * Follow [Step 6](https://catalog.workshops.aws/cloudwan/en-US/3-labs/lab1/step-6) in the workshop guide to configure the VPN connection.
2. If you want to build the end architecture after finishing the steps:
  * Uncomment everything in `CoreNetwork.yaml`.
  * Execute `make deploy-lab2`.

Use `make undeploy` to clean-up the test environment and avoid undesired charges.

### Lab 3 - Additional inspection scenarios

1. If you want to follow the lab guide, check point 2 in [Lab 2](#lab-2---federate-with-aws-transit-gateway) to uncomment the corresponding lines and do `make deploy-lab1` to build the initial environment.
2. If you want to build the end architecture after finishing the steps:
  * Update the Core Network definition in `CoreNetwork.yaml` with the code below.
  * Execute `make deploy-lab3`.

```yaml
  CoreNetwork:
    Type: AWS::NetworkManager::CoreNetwork
    Properties:
      Description: Core Network - AWS Cloud WAN workshop
      GlobalNetworkId: !Ref GlobalNetwork
      Tags: 
        - Key: Name
          Value: core-network-cwan-workshop
      PolicyDocument:
        version: "2021.12"
        core-network-configuration:
          vpn-ecmp-support: false
          asn-ranges:
            - 64520-65525
          edge-locations:
            - location: eu-north-1
            - location: us-west-2
        segments:
          - name: prod
            require-attachment-acceptance: false
            edge-locations:
              - eu-north-1
              - us-west-2
          - name: thirdparty
            isolate-attachments: true
            require-attachment-acceptance: false
            edge-locations:
              - eu-north-1
              - us-west-2
          - name: onpremises
            require-attachment-acceptance: false
          - name: legacy
            require-attachment-acceptance: false
            edge-locations:
              - eu-north-1
              - us-west-2
        network-function-groups:
          - name: EgressInspectionVpcs
            require-attachment-acceptance: false
          - name: InspectionVpcs
            require-attachment-acceptance: false
        attachment-policies:
          - rule-number: 100
            condition-logic: or
            conditions:
              - type: tag-value
                operator: equals
                key: nfg
                value: inspection
            action:
              add-to-network-function-group: InspectionVpcs
          - rule-number: 200
            condition-logic: or
            conditions:
              - type: tag-value
                operator: equals
                key: nfg
                value: egressinspection
            action:
              add-to-network-function-group: EgressInspectionVpcs
          - rule-number: 300
            condition-logic: or
            conditions:
              - type: tag-exists
                key: domain
            action:
              association-method: tag
              tag-value-of-key: domain
          - rule-number: 400
            condition-logic: or
            conditions:
              - type: attachment-type
                operator: equals
                value: transit-gateway-route-table
            action:
              association-method: constant
              segment: legacy
        segment-actions:
          - action: send-to
            segment: prod
            via:
              network-function-groups:
                - EgressInspectionVpcs
          - action: send-to
            segment: thirdparty
            via:
              network-function-groups:
                - EgressInspectionVpcs
          - action: send-via
            segment: thirdparty
            mode: single-hop
            when-sent-to:
              segments:
                - prod   
            via:
              network-function-groups:
                - EgressInspectionVpcs
          - action: send-via
            segment: prod
            mode: single-hop
            when-sent-to:
              segments:
                - onpremises
            via:
              network-function-groups:
                - EgressInspectionVpcs
              with-edge-overrides:
                - edge-sets:
                    - - us-west-2
                      - eu-north-1
                  use-edge-location: eu-north-1
          - action: send-via
            segment: thirdparty
            mode: single-hop
            via:
              network-function-groups:
                - EgressInspectionVpcs
              with-edge-overrides:
                - edge-sets:
                    - - us-west-2
                      - eu-north-1
                  use-edge-location: eu-north-1
          - action: share
            mode: attachment-route
            segment: legacy
            share-with:
              - prod
```

Use `make undeploy` to clean-up the test environment and avoid undesired charges.