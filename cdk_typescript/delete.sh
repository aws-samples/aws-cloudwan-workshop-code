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


# This script will delete all stacks that are deployed with this project.

if [[ -n "$AWS_PROFILE" ]]; then
  profile_opt="--profile $AWS_PROFILE"
else
  profile_opt=""
fi

# Delete all workload stacks
npx cdk destroy WorkloadProdUS WorkloadNonProdUS WorkloadProdEU WorkloadNonProdEU $profile_opt

# Delete all firewall stacks
npx cdk destroy InspectionUS InspectionEU $profile_opt

# Delete CloudWAN stack
npx cdk destroy CloudWAN $profile_opt

