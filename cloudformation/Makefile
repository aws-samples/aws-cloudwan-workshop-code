.PHONY: deploy deploy-initial deploy-cloudwan deploy-vpc-attachments deploy-vpc-routes deploy-peering deploy-tgwrt-attachments deploy-legacy-routes update-cloudwan undeploy

WORKLOAD_STACK_NAME ?= workloads
INSPECTION_STACK_NAME ?= inspection
CLOUDWAN_STACK_NAME ?= cloudwan
LEGACY_STACK_NAME ?= legacy

deploy: deploy-cloudwan deploy-vpc-routes deploy-legacy-routes
	
deploy-initial: 
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1

deploy-cloudwan:
	aws cloudformation deploy --stack-name "$(CLOUDWAN_STACK_NAME)" --template-file CoreNetwork.yaml --no-fail-on-empty-changeset --region us-west-2

deploy-vpc-attachments: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-west-2 )
deploy-vpc-attachments: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-west-2 )
deploy-vpc-attachments:
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" CreateCWANAttachment="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" CreateCWANAttachment="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" CreateCWANAttachment="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" CreateCWANAttachment="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1

deploy-vpc-routes: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-west-2 )
deploy-vpc-routes: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-west-2 )
deploy-vpc-routes:
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" CreateCWANAttachment="true" CreateVPCRoutes="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" CreateCWANAttachment="true" CreateVPCRoutes="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" CreateCWANAttachment="true" CreateVPCRoutes="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" CreateCWANAttachment="true" CreateVPCRoutes="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1

deploy-peering: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-west-2 )
deploy-peering:
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CreateCWANPeering="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CreateCWANPeering="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1

deploy-tgwrt-attachments: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-west-2 )
deploy-tgwrt-attachments: 
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CreateCWANPeering="true" CreateCWANAttachment="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CreateCWANPeering="true" CreateCWANAttachment="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1

deploy-legacy-routes: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-west-2 )
deploy-legacy-routes: 
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CreateCWANPeering="true" CreateCWANAttachment="true" CreateVPCRoutes="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CreateCWANPeering="true" CreateCWANAttachment="true" CreateVPCRoutes="true" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1

update-cloudwan: FIREWALL_ATTACHMENT_ID_US = $(shell aws networkmanager list-attachments | jq '.Attachments[] | select((.SegmentName=="sharedservices") and (.EdgeLocation=="us-west-2"))' | jq .AttachmentId )
update-cloudwan: FIREWALL_ATTACHMENT_ID_EU = $(shell aws networkmanager list-attachments | jq '.Attachments[] | select((.SegmentName=="sharedservices") and (.EdgeLocation=="eu-north-1"))' | jq .AttachmentId )
update-cloudwan:
	aws cloudformation deploy --stack-name "$(CLOUDWAN_STACK_NAME)" --template-file CoreNetwork.yaml --no-fail-on-empty-changeset --region us-west-2 --parameter-overrides UseInitialPolicy="No" FirewallAttachmentIdEU=${FIREWALL_ATTACHMENT_ID_EU} FirewallAttachmentIdUS=${FIREWALL_ATTACHMENT_ID_US}

undeploy: undeploy-oregon undeploy-stockholm undeploy-cloudwan

undeploy-oregon: WORKLOAD_STACK_ID = $(shell aws cloudformation list-stacks --region us-west-2 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${WORKLOAD_STACK_NAME}")' | jq .StackId -r)
undeploy-oregon: INSPECTION_STACK_ID = $(shell aws cloudformation list-stacks --region us-west-2 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${INSPECTION_STACK_NAME}")' | jq .StackId -r)
undeploy-oregon: LEGACY_STACK_ID = = $(shell aws cloudformation list-stacks --region us-west-2 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${LEGACY_STACK_NAME}")' | jq .StackId -r)
undeploy-oregon:
	aws cloudformation delete-stack --stack-name "$(WORKLOAD_STACK_NAME)" --region us-west-2
	aws cloudformation delete-stack --stack-name "$(INSPECTION_STACK_NAME)" --region us-west-2
	aws cloudformation delete-stack --stack-name "$(LEGACY_STACK_NAME)" --region us-west-2
	aws cloudformation wait stack-delete-complete --stack-name "${WORKLOAD_STACK_ID}" --region us-west-2
	aws cloudformation wait stack-delete-complete --stack-name "${INSPECTION_STACK_ID}" --region us-west-2
	aws cloudformation wait stack-delete-complete --stack-name "${LEGACY_STACK_ID}" --region us-west-2

undeploy-stockholm: WORKLOAD_STACK_ID = $(shell aws cloudformation list-stacks --region eu-north-1 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${WORKLOAD_STACK_NAME}")' | jq .StackId -r)
undeploy-stockholm: INSPECTION_STACK_ID = $(shell aws cloudformation list-stacks --region eu-north-1 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${INSPECTION_STACK_NAME}")' | jq .StackId -r)
undeploy-stockholm: LEGACY_STACK_ID = = $(shell aws cloudformation list-stacks --region eu-north-1 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${LEGACY_STACK_NAME}")' | jq .StackId -r)
undeploy-stockholm:
	aws cloudformation delete-stack --stack-name "$(WORKLOAD_STACK_NAME)" --region eu-north-1
	aws cloudformation delete-stack --stack-name "$(INSPECTION_STACK_NAME)" --region eu-north-1
	aws cloudformation delete-stack --stack-name "$(LEGACY_STACK_NAME)" --region eu-north-1
	aws cloudformation wait stack-delete-complete --stack-name "${WORKLOAD_STACK_ID}" --region eu-north-1
	aws cloudformation wait stack-delete-complete --stack-name "${INSPECTION_STACK_ID}" --region eu-north-1
	aws cloudformation wait stack-delete-complete --stack-name "${LEGACY_STACK_ID}" --region eu-north-1

undeploy-cloudwan: CLOUDWAN_STACK_ID = $(shell aws cloudformation list-stacks --region us-west-2 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${CLOUDWAN_STACK_NAME}")' | jq .StackId -r)
undeploy-cloudwan:
	aws cloudformation delete-stack --stack-name "$(CLOUDWAN_STACK_NAME)" --region us-west-2
	aws cloudformation wait stack-delete-complete --stack-name "${CLOUDWAN_STACK_ID}" --region us-west-2
