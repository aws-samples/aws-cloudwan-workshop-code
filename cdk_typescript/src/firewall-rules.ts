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


import { aws_networkfirewall as firewall } from 'aws-cdk-lib';
import { Construct } from 'constructs';

export class NetworkFirewallRules extends Construct {

  readonly firewallPolicy: firewall.CfnFirewallPolicy;

  constructor(scope: Construct, id: string) {
    super(scope, id);


    /*
    * Stateless firewall rules
    * Allow ICMP to both directions
    */
    const fwStatefulAllowRuleGroup = new firewall.CfnRuleGroup(this, 'fwAllowStatelessRuleGroup', {
      capacity: 10,
      ruleGroupName: 'AllowStateless',
      type: 'STATELESS',
      ruleGroup: {
        rulesSource: {
          statelessRulesAndCustomActions: {
            statelessRules: [
              {
                priority: 1,
                ruleDefinition: {
                  actions: ['aws:pass'],
                  matchAttributes: {
                    protocols: [1], // Protocol 1 is ICMP
                    sources: [{
                      addressDefinition: '0.0.0.0/0',
                    }],
                    destinations: [{
                      addressDefinition: '0.0.0.0/0',
                    }],
                  },
                },
              },
            ],
          },
        },
      },
    });

    /*
      * Statefull firewall rules
      * Allow HTTP/HTTPS and NTP traffic anywhere from organisation network
      */
    const fwAllowRuleGroup = new firewall.CfnRuleGroup(this, 'fwAllowRuleGroup', {
      capacity: 10,
      ruleGroupName: 'AllowRules',
      type: 'STATEFUL',
      description: 'Allow traffic to Internet',
      ruleGroup: {
        rulesSource: {
          statefulRules: [
            {
              action: 'PASS',
              header: {
                destination: 'ANY',
                destinationPort: '80',
                source: '10.0.0.0/8',
                sourcePort: 'ANY',
                protocol: 'TCP',
                direction: 'FORWARD',
              },
              ruleOptions: [{
                keyword: 'sid:1',
              }],
            },
            {
              action: 'PASS',
              header: {
                destination: 'ANY',
                destinationPort: '443',
                source: '10.0.0.0/8',
                sourcePort: 'ANY',
                protocol: 'TCP',
                direction: 'FORWARD',
              },
              ruleOptions: [{
                keyword: 'sid:2',
              }],
            },
            {
              action: 'PASS',
              header: {
                destination: 'ANY',
                destinationPort: '123',
                source: '10.0.0.0/8',
                sourcePort: 'ANY',
                protocol: 'UDP',
                direction: 'FORWARD',
              },
              ruleOptions: [{
                keyword: 'sid:3',
              }],
            },
          ],
        },
      },
    });


    /*
      * Deny rule group
      * Drop all traffic that is not explicitly defined in allow rule groups
      */

    const fwDenyRuleGroup = new firewall.CfnRuleGroup(this, 'fwDenyRuleGroup', {
      capacity: 10,
      ruleGroupName: 'DenyAll',
      type: 'STATEFUL',
      description: 'Deny all other traffic',
      ruleGroup: {
        rulesSource: {
          statefulRules: [
            {
              action: 'DROP',
              header: {
                destination: 'ANY',
                destinationPort: 'ANY',
                source: 'ANY',
                sourcePort: 'ANY',
                protocol: 'IP',
                direction: 'FORWARD',
              },
              ruleOptions: [{
                keyword: 'sid:100',
              }],
            },
          ],
        },
      },
    });


    // Firewall policy to enable stateless and statefull rule groups
    this.firewallPolicy = new firewall.CfnFirewallPolicy(this, 'FWPolicy', {
      firewallPolicy: {
        statelessDefaultActions: ['aws:forward_to_sfe'],
        statelessFragmentDefaultActions: ['aws:forward_to_sfe'],
        statelessRuleGroupReferences: [
          { resourceArn: fwStatefulAllowRuleGroup.attrRuleGroupArn, priority: 1 },
        ],
        statefulRuleGroupReferences: [
          { resourceArn: fwAllowRuleGroup.attrRuleGroupArn },
          { resourceArn: fwDenyRuleGroup.attrRuleGroupArn },
        ],
      },
      firewallPolicyName: 'SamplePolicy',
    });

  }
}

