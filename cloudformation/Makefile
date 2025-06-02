.PHONY: deploy-initial deploy-cloudwan deploy-initial-oregon deploy-initial-stockholm deploy-onprem deploy-lab1-oregon deploy-lab1-stockholm deploy-vpn deploy-lab2 deploy-lab2-oregon deploy-lab2-stockholm undeploy undeploy-oregon undeploy-stockholm undeploy-onprem undeploy-cloudwan

WORKLOAD_STACK_NAME ?= workloads
INSPECTION_STACK_NAME ?= inspection
CLOUDWAN_STACK_NAME ?= cloudwan
LEGACY_STACK_NAME ?= legacy
ONPREM_STACK_NAME ?= onprem
VPN_STACK_NAME ?= vpn

deploy-initial: deploy-cloudwan deploy-initial-oregon deploy-initial-stockholm deploy-onprem update-cloudwan

deploy-cloudwan:
	aws cloudformation deploy --stack-name "$(CLOUDWAN_STACK_NAME)" --template-file CoreNetwork.yaml --no-fail-on-empty-changeset --region us-west-2

update-cloudwan:
	aws cloudformation deploy --stack-name "$(CLOUDWAN_STACK_NAME)" --template-file CoreNetwork.yaml --no-fail-on-empty-changeset --region us-west-2

deploy-initial: deploy-initial-oregon deploy-initial-stockholm deploy-onprem

deploy-initial-oregon:
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2

deploy-initial-stockholm:
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1

deploy-onprem:
	aws cloudformation deploy --stack-name "$(ONPREM_STACK_NAME)" --template-file OnPremises.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-west-2

deploy-lab1: deploy-cloudwan deploy-lab1-oregon deploy-lab1-stockholm deploy-onprem deploy-vpn

deploy-lab1-oregon: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-west-2 )
deploy-lab1-oregon: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-west-2 )
deploy-lab1-oregon:
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab1" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab1" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2

deploy-lab1-stockholm: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-west-2 )
deploy-lab1-stockholm: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-west-2 )
deploy-lab1-stockholm:
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab1" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab1" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1

deploy-vpn: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-west-2 )
deploy-vpn: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-west-2 )
deploy-vpn: CGWPUBLICIP = $(shell aws cloudformation describe-stacks --stack-name "$(ONPREM_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CgwPublicIp`].OutputValue' --output text --region eu-west-2 )
deploy-vpn:
	aws cloudformation deploy --stack-name "$(VPN_STACK_NAME)" --template-file VPN.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" CgwPublicIp="$(CGWPUBLICIP)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1

deploy-lab2: deploy-cloudwan deploy-lab2-oregon deploy-lab2-stockholm deploy-onprem deploy-vpn

deploy-lab2-oregon: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-west-2 )
deploy-lab2-oregon: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-west-2 )
deploy-lab2-oregon:
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab2" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab2" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab2" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2

deploy-lab2-stockholm: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-west-2 )
deploy-lab2-stockholm: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-west-2 )
deploy-lab2-stockholm:
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab1" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab1" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab2" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1

deploy-lab3: deploy-cloudwan deploy-lab3-oregon deploy-lab3-stockholm deploy-onprem deploy-vpn

deploy-lab3-oregon: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-west-2 )
deploy-lab3-oregon: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-west-2 )
deploy-lab3-oregon:
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab3" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab3" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab3" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2

deploy-lab3-stockholm: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-west-2 )
deploy-lab3-stockholm: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "$(CLOUDWAN_STACK_NAME)" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-west-2 )
deploy-lab3-stockholm:
	aws cloudformation deploy --stack-name "$(WORKLOAD_STACK_NAME)" --template-file Workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab3" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1
	aws cloudformation deploy --stack-name "$(INSPECTION_STACK_NAME)" --template-file Inspection.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab3" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1
	aws cloudformation deploy --stack-name "$(LEGACY_STACK_NAME)" --template-file Legacy.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" Deployment="lab3" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-north-1

undeploy: undeploy-oregon undeploy-stockholm undeploy-onprem undeploy-cloudwan

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

undeploy-onprem: ONPREM_STACK_ID = $(shell aws cloudformation list-stacks --region eu-west-2 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${ONPREM_STACK_NAME}")' | jq .StackId -r)
undeploy-onprem: VPN_STACK_ID = $(shell aws cloudformation list-stacks --region eu-north-1 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${VPN_STACK_NAME}")' | jq .StackId -r)
undeploy-onprem:
	aws cloudformation delete-stack --stack-name "$(ONPREM_STACK_NAME)" --region eu-west-2
	aws cloudformation delete-stack --stack-name "$(VPN_STACK_NAME)" --region eu-north-1
	aws cloudformation wait stack-delete-complete --stack-name "${ONPREM_STACK_ID}" --region eu-west-2
	aws cloudformation wait stack-delete-complete --stack-name "${VPN_STACK_ID}" --region eu-north-1

undeploy-cloudwan: CLOUDWAN_STACK_ID = $(shell aws cloudformation list-stacks --region us-west-2 | jq '.StackSummaries[] | select(.StackStatus=="DELETE_COMPLETE" | not)' | jq 'select(.StackName=="${CLOUDWAN_STACK_NAME}")' | jq .StackId -r)
undeploy-cloudwan:
	aws cloudformation delete-stack --stack-name "$(CLOUDWAN_STACK_NAME)" --region us-west-2
	aws cloudformation wait stack-delete-complete --stack-name "${CLOUDWAN_STACK_ID}" --region us-west-2
