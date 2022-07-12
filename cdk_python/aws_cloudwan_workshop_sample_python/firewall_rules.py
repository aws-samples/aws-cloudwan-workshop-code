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

from aws_cdk import aws_networkfirewall as firewall
from constructs import Construct


class NetworkFirewallRules(Construct):
    def __init__(self, scope: "Construct", id: str) -> None:
        super().__init__(scope, id)
        fw_statefull_allow_rulegroup = firewall.CfnRuleGroup(
            self,
            "fwAllowStatelessRuleGroup",
            capacity=10,
            rule_group_name="AllowStateless",
            type="STATELESS",
            rule_group=firewall.CfnRuleGroup.RuleGroupProperty(
                rules_source=firewall.CfnRuleGroup.RulesSourceProperty(
                    stateless_rules_and_custom_actions=firewall.CfnRuleGroup.StatelessRulesAndCustomActionsProperty(
                        stateless_rules=[
                            firewall.CfnRuleGroup.StatelessRuleProperty(
                                priority=1,
                                rule_definition=firewall.CfnRuleGroup.RuleDefinitionProperty(
                                    actions=["aws:pass"],
                                    match_attributes=firewall.CfnRuleGroup.MatchAttributesProperty(
                                        protocols=[1],
                                        sources=[
                                            firewall.CfnRuleGroup.AddressProperty(
                                                address_definition="0.0.0.0/0"
                                            )
                                        ],
                                        destinations=[
                                            firewall.CfnRuleGroup.AddressProperty(
                                                address_definition="0.0.0.0/0"
                                            )
                                        ],
                                    ),
                                ),
                            )
                        ]
                    )
                )
            ),
        )

        fw_allow_rule_group = firewall.CfnRuleGroup(
            self,
            "fwAllowRuleGroup",
            capacity=10,
            rule_group_name="AllowRules",
            type="STATEFUL",
            description="Allow traffic to Internet",
            rule_group=firewall.CfnRuleGroup.RuleGroupProperty(
                rules_source=firewall.CfnRuleGroup.RulesSourceProperty(
                    stateful_rules=[
                        firewall.CfnRuleGroup.StatefulRuleProperty(
                            action="PASS",
                            header=firewall.CfnRuleGroup.HeaderProperty(
                                destination="ANY",
                                destination_port="80",
                                source="10.0.0.0/8",
                                source_port="ANY",
                                protocol="TCP",
                                direction="FORWARD",
                            ),
                            rule_options=[
                                firewall.CfnRuleGroup.RuleOptionProperty(
                                    keyword="sid:1"
                                )
                            ],
                        ),
                        firewall.CfnRuleGroup.StatefulRuleProperty(
                            action="PASS",
                            header=firewall.CfnRuleGroup.HeaderProperty(
                                destination="ANY",
                                destination_port="443",
                                source="10.0.0.0/8",
                                source_port="ANY",
                                protocol="TCP",
                                direction="FORWARD",
                            ),
                            rule_options=[
                                firewall.CfnRuleGroup.RuleOptionProperty(
                                    keyword="sid:2"
                                )
                            ],
                        ),
                        firewall.CfnRuleGroup.StatefulRuleProperty(
                            action="PASS",
                            header=firewall.CfnRuleGroup.HeaderProperty(
                                destination="ANY",
                                destination_port="123",
                                source="10.0.0.0/8",
                                source_port="ANY",
                                protocol="UDP",
                                direction="FORWARD",
                            ),
                            rule_options=[
                                firewall.CfnRuleGroup.RuleOptionProperty(
                                    keyword="sid:3"
                                )
                            ],
                        ),
                    ]
                )
            ),
        )

        fw_deny_rule_group = firewall.CfnRuleGroup(
            self,
            "fwDenyRuleGroup",
            capacity=10,
            rule_group_name="DenyAll",
            type="STATEFUL",
            description="Deny all other traffic",
            rule_group=firewall.CfnRuleGroup.RuleGroupProperty(
                rules_source=firewall.CfnRuleGroup.RulesSourceProperty(
                    stateful_rules=[
                        firewall.CfnRuleGroup.StatefulRuleProperty(
                            action="DROP",
                            header=firewall.CfnRuleGroup.HeaderProperty(
                                destination="ANY",
                                destination_port="ANY",
                                source="ANY",
                                source_port="ANY",
                                protocol="IP",
                                direction="FORWARD",
                            ),
                            rule_options=[
                                firewall.CfnRuleGroup.RuleOptionProperty(
                                    keyword="sid:100"
                                )
                            ],
                        ),
                    ]
                )
            ),
        )

        self._firewall_policy = firewall.CfnFirewallPolicy(
            self,
            "FWPolicy",
            firewall_policy=firewall.CfnFirewallPolicy.FirewallPolicyProperty(
                stateless_default_actions=["aws:forward_to_sfe"],
                stateless_fragment_default_actions=["aws:forward_to_sfe"],
                stateless_rule_group_references=[
                    firewall.CfnFirewallPolicy.StatelessRuleGroupReferenceProperty(
                        priority=1,
                        resource_arn=fw_statefull_allow_rulegroup.attr_rule_group_arn,
                    )
                ],
                stateful_rule_group_references=[
                    firewall.CfnFirewallPolicy.StatefulRuleGroupReferenceProperty(
                        resource_arn=fw_allow_rule_group.attr_rule_group_arn
                    ),
                    firewall.CfnFirewallPolicy.StatefulRuleGroupReferenceProperty(
                        resource_arn=fw_deny_rule_group.attr_rule_group_arn
                    ),
                ],
            ),
            firewall_policy_name="SamplePolicy",
        )

    @property
    def firewall_policy(self) -> firewall.CfnFirewallPolicy:
        return self._firewall_policy
