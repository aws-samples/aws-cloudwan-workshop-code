import { App, Stack } from 'aws-cdk-lib';
import { Capture, Template } from 'aws-cdk-lib/assertions';
import { CloudWanStack } from '../src/cloudwan-stack';

let stack: Stack;

beforeAll(() => {
  const app = new App();
  stack = new CloudWanStack(app, 'test', {
    env: {
      region: 'us-east-1',
    },
    policyFile: 'cloudwan-policy-init.json',
  });
});

test('Snapshot', () => {
  const template = Template.fromStack(stack);
  expect(template.toJSON()).toMatchSnapshot();
});

test('CloudWan', () => {
  const template = Template.fromStack(stack);

  template.resourceCountIs('AWS::NetworkManager::GlobalNetwork', 1);

  const id = new Capture();
  template.hasResourceProperties('AWS::NetworkManager::CoreNetwork', {
    Tags: [
      { Key: 'Env', Value: 'Workshop' },
      { Key: 'Name', Value: 'CoreNetwork' },
    ],
    GlobalNetworkId: id,
  });
  expect(id.asObject()).toHaveProperty('Fn::GetAtt', ['GlobalNet', 'Id']);
});