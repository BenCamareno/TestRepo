#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { fromContext } from '../lib/common/context'
import * as vpc from '../lib/common/vpc'
import { AwsIdentityCdkStack } from '../lib/aws-identity-cdk-stack';

const app = new cdk.App();
const region = fromContext(app, 'region') as string;
const canaryBuildAccount = { account: '1111111111111', region: region };
const previewSailPoint = { account: '11111111111', region: region };
const gaNonProdSailPoint = { account: '1111111111111', region: region };
const gaProdSailPoint = { account: '1111111111111', region: region };
const canaryMgmtSubnets = fromContext(app, 'canaryMgmtSubnets') as vpc.SubnetProps[];
const previewMgmtSubnets = fromContext(app, 'previewMgmtSubnets') as vpc.SubnetProps[];
const nonpMgmtSubnets = fromContext(app, 'nonpMgmtSubnets') as vpc.SubnetProps[];
const prodMgmtSubnets = fromContext(app, 'prodMgmtSubnets') as vpc.SubnetProps[];
const canaryMgmtSGId = fromContext(app, 'canaryMgmtSGId') as string
const previewMgmtSGId = fromContext(app, 'previewMgmtSGId') as string
const nonpMgmtSGId = fromContext(app, 'nonpMgmtSGId') as string
const prodMgmtSGId = fromContext(app, 'prodMgmtSGId') as string
const featureBranch = process.env.FEATURE_BRANCH
const featureBranchDeploymentEnabled = process.env.FEATURE_BRANCH_DEPLOYMENT_ENABLED ?? 'false'

function isFeatureBranchDeploymentEnabled():boolean{
  return ['true', 'True', 'TRUE', 'yes', 'Yes', 'YES'].includes(featureBranchDeploymentEnabled)
}

console.log("debug process.env.FEATURE_BRANCH_DEPLOYMENT_ENABLED:"+process.env.FEATURE_BRANCH_DEPLOYMENT_ENABLED)
console.log("debug featureBranch:"+featureBranch)
console.log("debug featureBranchDeploymentEnabled:"+featureBranchDeploymentEnabled)
console.log("debug isFeatureBranchDeploymentEnabled:"+isFeatureBranchDeploymentEnabled())

// Feature Stack for Identity Statemachine
if (isFeatureBranchDeploymentEnabled()){
  let stackName = `AwsIdentityStatemachineStack-${featureBranch}`
  console.log("debug stackName:"+stackName)
  new AwsIdentityCdkStack(app, stackName, {
    env: previewSailPoint,
    lambdaExecutionRole: "arn:aws:iam::1111111111111:role/AWSProtectLambdaExecutionRole",
    statemachineExecutionRole: "arn:aws:iam::1111111111111:role/IdentityStateMachineExecutionRole",
    nexusCallbackCrossAccountRole: "arn:aws:iam::1111111111111:role/nexus-preview-identity-automation-callback-role",
    mgmtSubnets: previewMgmtSubnets,
    mgmtSecurityGroup: [previewMgmtSGId],
    eventBusArn: "arn:aws:events:ap-southeast-2:1111111111111:event-bus/default",
    nexusIAMPrincipal: "arn:aws:iam::1111111111111:root",
    source: "ccc.onecloud.workspace.test",
    release_channel: ["preview"],
    service_tier: ["nonp", "clab"],
    branch: featureBranch
  });
};

// Canary Stack for Identity Statemachine
new AwsIdentityCdkStack(app, 'AwsIdentityStatemachineStack-canary', {
  env: canaryBuildAccount,
  lambdaExecutionRole: "arn:aws:iam::1111111111111:role/AWSProtectLambdaExecutionRole",
  statemachineExecutionRole: "arn:aws:iam::1111111111111:role/IdentityStateMachineExecutionRole",
  nexusCallbackCrossAccountRole: "arn:aws:iam::1111111111111:role/nexus-preview-identity-automation-callback-role",
  mgmtSubnets: canaryMgmtSubnets,
  mgmtSecurityGroup: [canaryMgmtSGId],
  eventBusArn: "arn:aws:events:ap-southeast-2:1111111111111:event-bus/default",
  nexusIAMPrincipal: "arn:aws:iam::819074484189:root",
  source: "ccc.onecloud.workspace.test",
  release_channel: ["canary"],
  service_tier: ["clab"]
});

// Preview Stack for Identity Statemachine 
new AwsIdentityCdkStack(app, 'AwsIdentityStatemachineStack-preview', {
  env: previewSailPoint,
  lambdaExecutionRole: "arn:aws:iam::1111111111111:role/AWSProtectLambdaExecutionRole",
  statemachineExecutionRole: "arn:aws:iam::1111111111111:role/IdentityStateMachineExecutionRole",
  nexusCallbackCrossAccountRole: "arn:aws:iam::1111111111111:role/nexus-preview-identity-automation-callback-role",
  mgmtSubnets: previewMgmtSubnets,
  mgmtSecurityGroup: [previewMgmtSGId],
  eventBusArn: "arn:aws:events:ap-southeast-2:1111111111111:event-bus/default",
  nexusIAMPrincipal: "arn:aws:iam::819074484189:root",
  source: "ccc.onecloud.workspace.test",
  release_channel: ["preview"],
  service_tier: ["nonp", "clab"]
});

// Nonprod Stack for Identity Statemachine 
new AwsIdentityCdkStack(app, 'AwsIdentityStatemachineStack-nonprod', {
  env: gaNonProdSailPoint,
  lambdaExecutionRole: "arn:aws:iam::1111111111111:role/AWSProtectLambdaExecutionRole",
  statemachineExecutionRole: "arn:aws:iam::1111111111111:role/IdentityStateMachineExecutionRole",
  nexusCallbackCrossAccountRole: "arn:aws:iam::1111111111111:role/nexus-test-identity-automation-callback-role",
  mgmtSubnets: nonpMgmtSubnets,
  mgmtSecurityGroup: [nonpMgmtSGId],
  eventBusArn: "arn:aws:events:ap-southeast-2:1111111111111:event-bus/default",
  nexusIAMPrincipal: "arn:aws:iam::1111111111111:root",
  source: "ccc.onecloud.workspace.test",
  release_channel: ["ga"],
  service_tier: ["nonp", "clab"]
});

// Prod Stack for Identity Statemachine 
new AwsIdentityCdkStack(app, 'AwsIdentityStatemachineStack-prod', {
  env: gaProdSailPoint,
  lambdaExecutionRole: "arn:aws:iam::1111111111111:role/AWSProtectLambdaExecutionRole",
  statemachineExecutionRole: "arn:aws:iam::1111111111111:role/IdentityStateMachineExecutionRole",
  nexusCallbackCrossAccountRole: "arn:aws:iam::1111111111111:role/nexus-prod-identity-automation-callback-role",
  mgmtSubnets: prodMgmtSubnets,
  mgmtSecurityGroup: [prodMgmtSGId],
  eventBusArn: "arn:aws:events:ap-southeast-2:1111111111111:event-bus/default",
  nexusIAMPrincipal: "arn:aws:iam::1111111111111:root",
  source: "ccc.onecloud.workspace.prod",
  release_channel: ["ga","preview","canary"],
  service_tier: ["prod","nonp","clab"]
});
