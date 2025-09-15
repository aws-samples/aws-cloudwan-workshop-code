#!/usr/bin/env node
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.

// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify,
// merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import { execSync } from "child_process";
import { Command } from "commander";
import { regions } from "./bin/cloudwan-workshop-code";

// Deploy CloudWan Stack

const validDeployments: string[] = ["initial", "lab1", "lab2", "lab3"];

// Parse command line arguments
const program = new Command();
program
  .description("Deploy workshop stacks to AWS")
  .requiredOption(
    "--deployment <deployment>",
    "Lab to deploy. Valid values are [initial, lab1, lab2, lab3]"
  )
  .option("--profile <profile>", "AWS CLI profile name");

program.parse();
const options = program.opts();

// Verify that the requested lab is valid
if (options.lab && !validDeployments.includes(options.lab)) {
  console.error(
    `Invalid deployment: ${options.lab}\nValid labs are initial, lab1, lab2 or lab3`
  );
  process.exit(1);
}

// Always deploy Cloud WAN
if (options.profile) {
  execSync(
    `npx cdk deploy CloudWan --require-approval never --context lab=${options.deployment} --profile ${options.profile}`,
    { stdio: "inherit" }
  );
} else {
  execSync(
    `npx cdk deploy CloudWan --require-approval never --context lab=${options.deployment}`,
    { stdio: "inherit" }
  );
}

// Deploy requested labs

regions.forEach((region) => {
  if (options.profile) {
    execSync(
      `npx cdk deploy Inspection-${region} EgressInspection-${region} TransitGateway-${region} --context lab=${options.deployment} --concurrency 3 --require-approval never --profile ${options.profile}`,
      { stdio: "inherit" }
    );
    execSync(
      `npx cdk deploy ProductionWorkload-${region} ThirdPartyWorkload-${region} LegacyWorkload-${region} --context lab=${options.deployment}  --concurrency 3 --require-approval never --profile ${options.profile}`,
      { stdio: "inherit" }
    );
  } else {
    execSync(
      `npx cdk deploy Inspection-${region} EgressInspection-${region} TransitGateway-${region} --context lab=${options.deployment} --concurrency 3 --require-approval never`,
      { stdio: "inherit" }
    );
    execSync(
      `npx cdk deploy ProductionWorkload-${region} ThirdPartyWorkload-${region} LegacyWorkload-${region} --context lab=${options.deployment}  --concurrency 3 --require-approval never`,
      { stdio: "inherit" }
    );
  }
});

// Deploy single region resources
if (options.profile) {
  execSync(
    `npx cdk deploy Onpremises-eu-west-2 --require-approval never --profile ${options.profile}`,
    { stdio: "inherit" }
  );
  if (options.deployment !== "initial") {
    execSync(
      `npx cdk deploy Vpn-eu-north-1 --require-approval never --profile ${options.profile}`,
      { stdio: "inherit" }
    );
  }
} else {
  execSync(`npx cdk deploy Onpremises-eu-west-2 --require-approval never`, {
    stdio: "inherit",
  });
  if (options.deployment !== "initial") {
    execSync(
      `npx cdk deploy Vpn-eu-north-1 --require-approval never --profile ${options.profile}`,
      { stdio: "inherit" }
    );
  }
}
