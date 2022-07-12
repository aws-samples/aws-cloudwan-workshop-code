#!/usr/bin/env bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.

# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# This script will deploy all stacks in this project and can used only for initial deployment.
# Deployment is done in two passes. First time CloudWAN is deployed with initial policy file cloudwan-policy-init.json
# and all other stacks are deployed normally.
# In second pass, a TS code is run to get all CloudWAN attachments for inspection VPCs and then those are
# added to the active policy. New policy is then deployed to AWS by running CDK deploying CloudWAN stack again.

set -e

if [[ -f 'src/cloudwan-policy-active.json' ]]; then
  echo "CloudWAN active policy already exists. This script is meant to be used for initial deploy only. If you are redeploying, delete active policy at src/cloudwan-policy-active.json"
  exit 1
fi

# Set AWS credentials profile name if you are using named profiles
if [[ -n "$AWS_PROFILE" ]]; then
  profile_opt="--profile $AWS_PROFILE"
else
  profile_opt=""
fi

# Deploy CloudWAN stack first separately so that everything gets deployed properly before creating other resources.
npx cdk deploy CloudWAN "$profile_opt"

# # Deploy rest of the stacks
npx cdk deploy --all "$profile_opt"


# # # Run a script update CloudWAN policy with firewall attachment IDs
if ! npx ts-node update_policy_file.ts; then
  echo "Policy update script didn't finish correctly."
  exit 1
fi

# # File got generated. Let's continue and add new policy.
npx cdk deploy CloudWAN "$profile_opt"