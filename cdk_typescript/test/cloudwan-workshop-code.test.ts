// import * as cdk from 'aws-cdk-lib';
// import { Template } from 'aws-cdk-lib/assertions';
import { region, cloudWanRegion } from '../bin/cloudwan-workshop-code';

test('CloudWan region is one of all regions', () => {
  expect(region.includes(cloudWanRegion)).toBe(true);
})