const { awscdk } = require('projen');
const project = new awscdk.AwsCdkTypeScriptApp({
  cdkVersion: '2.31.1',
  defaultReleaseBranch: 'main',
  name: 'aws-cloudwan-workshop-cdk-example',
  constructsVersion: '10.1.43',
  deps: [
    '@aws-sdk/client-ec2',
    '@aws-sdk/client-network-firewall',
    'aws-lambda',
    '@types/aws-lambda',
    '@types/jest',
    'jest',
    '@aws-sdk/client-networkmanager',
  ],
  // deps: [],                /* Runtime dependencies of this module. */
  // description: undefined,  /* The description is just a string that helps people understand the purpose of the package. */
  // devDeps: [],             /* Build dependencies for this module. */
  // packageName: undefined,  /* The "name" in package.json. */
});
project.synth();