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

// Parse command line arguments
const program = new Command();
program
  .description("Destroy workshop stacks")
  .option("--profile <profile>", "AWS CLI profile name");

program.parse();
const options = program.opts();

// Destroy stacks

if (options.profile) {
  execSync(
    `npx cdk destroy Onpremises-eu-west-2 Vpn-eu-north-1 --force --profile ${options.profile}`,
    { stdio: "inherit" }
  );
} else {
  execSync(`npx cdk destroy Onpremises-eu-west-2 Vpn-eu-north-1 --force`, {
    stdio: "inherit",
  });
}

regions.forEach((region) => {
  if (options.profile) {
    execSync(
      `npx cdk destroy ProductionWorkload-${region} ThirdPartyWorkload-${region} LegacyWorkload-${region} --force --profile ${options.profile}`,
      { stdio: "inherit" }
    );
    execSync(
      `npx cdk destroy EgressInspection-${region} Inspection-${region} TransitGateway-${region} --force --profile ${options.profile}`,
      { stdio: "inherit" }
    );
  } else {
    execSync(
      `npx cdk destroy ProductionWorkload-${region} ThirdPartyWorkload-${region} LegacyWorkload-${region} --force`,
      { stdio: "inherit" }
    );
    execSync(
      `npx cdk destroy EgressInspection-${region} Inspection-${region} TransitGateway-${region} --force`,
      { stdio: "inherit" }
    );
  }
});

if (options.profile) {
  execSync(`npx cdk destroy CloudWan --force --profile ${options.profile}`, {
    stdio: "inherit",
  });
} else {
  execSync(`npx cdk destroy CloudWan --force`, { stdio: "inherit" });
}
