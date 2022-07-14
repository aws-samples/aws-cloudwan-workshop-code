.PHONY: deploy deploy-cloudwan deploy-ireland deploy-virginia undeploy undeploy-core undeploy-ireland undeploy-virginia

WORKLOAD_STACK_NAME ?= workloads
INSPECTION_STACK_NAME ?= inspection
CLOUDWAN_STACK_NAME ?= cloudwan

deploy: deploy-cloudwan deploy-ireland deploy-virginia deploy-cloudwan-active

deploy-cloudwan:
	aws cloudformation deploy --stack-name "$(CLOUDWAN_STACK_NAME)" --template-file CoreNetwork.yaml --no-fail-on-empty-changeset --region us-east-1

deploy-ireland: CLOUDWAN_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-east-1 )
deploy-ireland: CLOUDWAN_ARN = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-east-1 )
deploy-ireland:
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --parameter-overrides CloudWANID="$(CLOUDWAN_ID)" CloudWANARN="$(CLOUDWAN_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-west-1
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --parameter-overrides CloudWANID="$(CLOUDWAN_ID)" CloudWANARN="$(CLOUDWAN_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-west-1

deploy-virginia: CLOUDWAN_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-east-1 )
deploy-virginia: CLOUDWAN_ARN = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-east-1 )
deploy-virginia:
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --parameter-overrides CloudWANID="$(CLOUDWAN_ID)" CloudWANARN="$(CLOUDWAN_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-east-1
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --parameter-overrides CloudWANID="$(CLOUDWAN_ID)" CloudWANARN="$(CLOUDWAN_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-east-1

deploy-cloudwan-active: FIREWALL_ATTACHMENT_ID_EU = $(shell aws networkmanager list-attachments | jq '.Attachments[] | select((.SegmentName=="sharedservices") and (.EdgeLocation=="eu-west-1"))' | jq .AttachmentId )
deploy-cloudwan-active: FIREWALL_ATTACHMENT_ID_US = $(shell aws networkmanager list-attachments | jq '.Attachments[] | select((.SegmentName=="sharedservices") and (.EdgeLocation=="us-east-1"))' | jq .AttachmentId )
deploy-cloudwan-active:
	aws cloudformation deploy --stack-name "$(CLOUDWAN_STACK_NAME)" --template-file CoreNetwork.yaml --no-fail-on-empty-changeset --region us-east-1 --parameter-overrides UseInitialPolicy="No" FirewallAttachmentIdEU=${FIREWALL_ATTACHMENT_ID_EU} FirewallAttachmentIdUS=${FIREWALL_ATTACHMENT_ID_US}

undeploy: undeploy-virginia undeploy-ireland undeploy-cloudwan

undeploy-virginia: WORKLOAD_STACK_ID = $(shell aws cloudformation list-stacks --region us-east-1 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${WORKLOAD_STACK_NAME}")' | jq .StackId -r)
undeploy-virginia: INSPECTION_STACK_ID = $(shell aws cloudformation list-stacks --region us-east-1 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${INSPECTION_STACK_NAME}")' | jq .StackId -r)
undeploy-virginia:
	aws cloudformation delete-stack --stack-name "$(WORKLOAD_STACK_NAME)" --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name "${WORKLOAD_STACK_ID}" --region us-east-1
	aws cloudformation delete-stack --stack-name "$(INSPECTION_STACK_NAME)" --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name "${INSPECTION_STACK_ID}" --region us-east-1

undeploy-ireland: WORKLOAD_STACK_ID = $(shell aws cloudformation list-stacks --region eu-west-1 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${WORKLOAD_STACK_NAME}")' | jq .StackId -r)
undeploy-ireland: INSPECTION_STACK_ID = $(shell aws cloudformation list-stacks --region eu-west-1 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${INSPECTION_STACK_NAME}")' | jq .StackId -r)
undeploy-ireland:
	aws cloudformation delete-stack --stack-name "$(WORKLOAD_STACK_NAME)" --region eu-west-1
	aws cloudformation wait stack-delete-complete --stack-name "${WORKLOAD_STACK_ID}" --region eu-west-1
	aws cloudformation delete-stack --stack-name "$(INSPECTION_STACK_NAME)" --region eu-west-1
	aws cloudformation wait stack-delete-complete --stack-name "${INSPECTION_STACK_ID}" --region eu-west-1


undeploy-cloudwan: CLOUDWAN_STACK_ID = $(shell aws cloudformation list-stacks --region us-east-1 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${CLOUDWAN_STACK_NAME}")' | jq .StackId -r)
undeploy-cloudwan:
	aws cloudformation delete-stack --stack-name "$(CLOUDWAN_STACK_NAME)" --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name "${CLOUDWAN_STACK_ID}" --region us-east-1
