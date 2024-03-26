import pprint
import sys
from dataclasses import dataclass

import boto3
from botocore.exceptions import ClientError,WaiterError

import logging
import os
import traceback
from github_conn import get_cf_template

logger = logging.getLogger("privileged_sa_logger")
logger.setLevel(int(os.getenv("LOG_LEVEL", logging.INFO)))
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s - (%(filename)s:%(lineno)d)')
handler = logging.StreamHandler()
handler.setFormatter(formatter)
logger.addHandler(handler)

class InputValidationError(Exception):
    def __init__(self, message):
        self.message = message

@dataclass
class PrivilegedSaResponse:
    access_key_id: str
    secret_key: str
    aws_role_arn: str

@dataclass
class PrivilegedSaRequest:
    aws_account_id: str
    ci_number: str
    role_name: str
    trusted_role_cf_template_path: str = ""

    def sa_name(self):
        return self._sa_name

    def sa_policy_name(self):
        return self._sa_policy_name
    def sa_name_arn(self):
        return self._sa_name_arn

    def privileged_role_arn(self):
        return self._privileged_role_arn

    def stack_name(self):
        return f'cns-identity-pam-onboarding-sa-{self.role_name}'
    def sa_trust_policy_stack_name(self):
        return self._sa_trust_policy_stack_name
    def service_account_trust_policy_cf_template_path(self):
        return self._service_account_trust_policy_cf_template_path

    def __repr__(self):
        return f"""
        sa_name: {self.sa_name()}
        sa_policy_name: {self.sa_policy_name()}
        sa_name_arn: {self.sa_name_arn()}
        privileged_role_arn: {self.privileged_role_arn()}
        """

    def __post_init__(self):
        if not (self.aws_account_id and self.ci_number):
            raise InputValidationError("validation error: aws_account_id and ci_number are both required")
            return

        print("{:12} {:7}".format(self.aws_account_id, self.ci_number))
        sa_name_prefix=f'ACOE_CYBERARK_WS_{self.aws_account_id}_{self.ci_number}'
        self._sa_name = f'{sa_name_prefix}_service_account'
        self._sa_policy_name = f'{self._sa_name}_policy'
        self._sa_name_arn=f"arn:aws:iam::{self.aws_account_id}:user/{self._sa_name}"

        __privileged_role_name = f'{sa_name_prefix}_privileged_role'
        __privileged_role_policy_name = f'{__privileged_role_name}_policy'
        self._privileged_role_arn = f"arn:aws:iam::{self.aws_account_id}:role/{__privileged_role_name}"
        privileged_role_policy_arn = f"arn:aws:iam::{self.aws_account_id}:policy/{__privileged_role_policy_name}"
        self._sa_trust_policy_stack_name="CyberarkPriviligedSaTrustPolicyStack"
        self._service_account_trust_policy_cf_template_path="serviceaccounts/platform/test-privileged-sa-trust-policy.yaml"

def create_service_account(req: PrivilegedSaRequest) -> PrivilegedSaResponse:
    noneResponse=PrivilegedSaResponse('','','')
    logger.info(req)
    iam = boto3.client("iam")
    cf = boto3.client('cloudformation')

    # create a IAM user as service account
    try:
        create_user_result = iam.create_user(
            UserName=req.sa_name()
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'EntityAlreadyExists':
            logger.warning("User already exists")
        else:
            logger.error("Unexpected error: %s" % e)

    waiter = iam.get_waiter('user_exists')
    waiter.wait(
        UserName=req.sa_name(),
        WaiterConfig={
            'Delay': 1,
            'MaxAttempts': 12
        }
    )

    # create sa trust policy using cf template
    logger.info(f"fetch sa trust policy at:{req.service_account_trust_policy_cf_template_path()}")
    sa_trust_policy_template=get_cf_template(req.service_account_trust_policy_cf_template_path())
    # logger.info("debug role template:{}".format(sa_trust_policy_template))

    response = cf.validate_template(
        TemplateBody=sa_trust_policy_template
    )

    if response.get('ResponseMetadata').get('HTTPStatusCode')!=200:
        print("Error in validating CF template, inspect: {}".format(response))
        return noneResponse

    print("Creating sa trust policy stack:{}".format(req.sa_trust_policy_stack_name()))
    try:
        response = cf.create_stack(
            StackName=req.sa_trust_policy_stack_name(),
            TemplateBody=sa_trust_policy_template,
            Parameters=[
                {
                'ParameterKey': 'SharedServiceAccount',
                'ParameterValue': req.sa_name()
                },
                {
                'ParameterKey': 'PrivilegedRoleArn',
                'ParameterValue': req.privileged_role_arn()
                }
            ],
            Capabilities=[
                'CAPABILITY_IAM','CAPABILITY_NAMED_IAM','CAPABILITY_AUTO_EXPAND'
            ]
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'AlreadyExistsException':
            logger.warning("sa trust policy stack already exists, try to update instead ...")

            #===
            print("update sa trust policy stack:{}".format(req.sa_trust_policy_stack_name()))
            try:
                response = cf.update_stack(
                    StackName=req.sa_trust_policy_stack_name(),
                    TemplateBody=sa_trust_policy_template,
                    Parameters=[
                        {
                            'ParameterKey': 'SharedServiceAccount',
                            'ParameterValue': req.sa_name()
                        },
                        {
                            'ParameterKey': 'PrivilegedRoleArn',
                            'ParameterValue': req.privileged_role_arn()
                        }
                    ],
                    Capabilities=[
                        'CAPABILITY_IAM','CAPABILITY_NAMED_IAM','CAPABILITY_AUTO_EXPAND'
                    ]
                )
            except ClientError as e:
                if e.response['Error']['Code'] == 'ValidationError':
                    # traceback.print_exc()  # Print the detailed stack trace
                    logger.warning(f"stack: {req.sa_trust_policy_stack_name()} no update required")
                    logger.warning("potential unhandled error to inspect: %s" % e)
                else:
                    logger.error("Unexpected error: %s" % e)

                describe_stack_response = cf.describe_stack_events(
                    StackName=req.sa_trust_policy_stack_name()
                )
                events=describe_stack_response.get('StackEvents')
                for event in events:
                    status=event.get('ResourceStatus')
                    if status.endswith('_FAILED'):
                        reason=event.get('ResourceStatusReason')
                        print("{:30} reason: {}".format(status, reason))

            if response.get('ResponseMetadata').get('HTTPStatusCode')!=200:
                print("Error in update CF {}, inspect: {}".format(req.sa_trust_policy_stack_name(),response))
                return noneResponse
        else:
            logger.error("Unexpected error: %s" % e)

    waiter = cf.get_waiter('stack_create_complete')
    try:
        waiter.wait(
            StackName=req.sa_trust_policy_stack_name(),
            WaiterConfig={
                'Delay': 10,
                'MaxAttempts': 12
            }
        )
    except WaiterError:
        response = cf.describe_stack_events(
            StackName=req.sa_trust_policy_stack_name()
        )
        events=response.get('StackEvents')
        for event in events:
            status=event.get('ResourceStatus')
            if status.endswith('_FAILED'):
                reason=event.get('ResourceStatusReason')
                print("{:30} reason: {}".format(status, reason))
        return noneResponse

    response = cf.describe_stacks(StackName=req.sa_trust_policy_stack_name())
    print("trust policy stack details:")
    pprint.pprint(response)
    outputs = response.get('Stacks')[0].get('Outputs')
    saTrustPolicyArn=None
    for output in outputs:
        if output['OutputKey']=='SaTrustPolicyArn':
            print("found: "+output['OutputKey'] + ': ' + output['OutputValue'])
            saTrustPolicyArn=output['OutputValue']
            logger.info(f"SA trust policy created: {saTrustPolicyArn}")

    if saTrustPolicyArn == None:
        logger.error("error in creating trust policy stack and get correct policy Arn")
        return noneResponse

    try:
        attach_sa_policy_result = iam.attach_user_policy(
            UserName=req.sa_name(),
            PolicyArn=saTrustPolicyArn
        )
    except UnboundLocalError:
        logger.warning("retrieve policy and try to attach ser policy")
        attach_sa_policy_result = iam.attach_user_policy(
            UserName=req.sa_name(),
            PolicyArn=saTrustPolicyArn
        )

    stack_name = req.stack_name()

    role_template=get_cf_template(req.trusted_role_cf_template_path)
    # logger.debug("debug role template:{}".format(role_template))

    response = cf.validate_template(
        TemplateBody=role_template
    )

    if response.get('ResponseMetadata').get('HTTPStatusCode')!=200:
        print("Error in validating CF template, inspect: {}".format(response))
        return noneResponse

    print("Creating stack:{}".format(stack_name))
    try:
        response = cf.create_stack(
            StackName=stack_name,
            TemplateBody=role_template,
            Parameters=[{ # set as necessary. Ex:
                'ParameterKey': 'SharedServiceAccount',
                'ParameterValue': req.sa_name()
            }],
            Capabilities=[
                'CAPABILITY_IAM','CAPABILITY_NAMED_IAM','CAPABILITY_AUTO_EXPAND'
            ]
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'AlreadyExistsException':
            logger.warning("privileged Role CF stack already exists, continue ...")
            print("update privileged Role CF stack:{}".format(req.stack_name()))
            try:
                response = cf.create_stack(
                    StackName=stack_name,
                    TemplateBody=role_template,
                    Parameters=[{ # set as necessary. Ex:
                        'ParameterKey': 'SharedServiceAccount',
                        'ParameterValue': req.sa_name()
                    }],
                    Capabilities=[
                        'CAPABILITY_IAM','CAPABILITY_NAMED_IAM','CAPABILITY_AUTO_EXPAND'
                    ]
                )

            except ClientError as e:
                if e.response['Error']['Code'] == 'ValidationError':
                    # traceback.print_exc()  # Print the detailed stack trace
                    logger.warning(f"stack: {req.stack_name()} no update required")
                    logger.warning("potential unhandled error to inspect: %s" % e)
                else:
                    logger.error("Unexpected error: %s" % e)

                describe_stack_response = cf.describe_stack_events(
                    StackName=req.stack_name()
                )
                events=describe_stack_response.get('StackEvents')
                for event in events:
                    status=event.get('ResourceStatus')
                    if status.endswith('_FAILED'):
                        reason=event.get('ResourceStatusReason')
                        print("{:30} reason: {}".format(status, reason))

            if response.get('ResponseMetadata').get('HTTPStatusCode')!=200:
                print("Error in update CF {}, inspect: {}".format(req.stack_name(),response))
                return noneResponse
        else:
            logger.error("Unexpected error: %s" % e)

    waiter = cf.get_waiter('stack_create_complete')
    try:
        waiter.wait(
            StackName=stack_name,
            WaiterConfig={
                'Delay': 10,
                'MaxAttempts': 12
            }
        )
    except WaiterError:
        response = cf.describe_stack_events(
            StackName=stack_name
        )
        events=response.get('StackEvents')
        for event in events:
            status=event.get('ResourceStatus')
            if status.endswith('_FAILED'):
                reason=event.get('ResourceStatusReason')
                print("{:30} reason: {}".format(status, reason))
        return noneResponse

    response = cf.describe_stacks(StackName=stack_name)
    # pprint.pprint(response)
    outputs = response.get('Stacks')[0].get('Outputs')
    for output in outputs:
        if output['OutputKey']=='PrivilegedRoleArn':
            print("found: "+output['OutputKey'] + ': ' + output['OutputValue'])
            privilegedRoleArn=output['OutputValue']
            logger.info(f"privileged role created: {privilegedRoleArn}")


    response = iam.list_access_keys(
        UserName=req.sa_name(),
    )

    if response.get('ResponseMetadata').get('HTTPStatusCode')!=200:
        print("Error in list access keys, inspect: {}".format(response))
        return noneResponse
    else:
        pprint.pprint(response)
        if len(response['AccessKeyMetadata'])==0:
            try:
                response = iam.create_access_key(
                    UserName=req.sa_name()
                )
                pprint.pprint(response)
            except ClientError as e:
                logger.error("Unexpected error in generating access key: %s" % e)
                return noneResponse

            if response.get('ResponseMetadata').get('HTTPStatusCode')!=200:
                print("Error in generating access key, inspect: {}".format(response))
            else:
                return PrivilegedSaResponse(response['AccessKey']['AccessKeyId'], response['AccessKey']['SecretAccessKey'], privilegedRoleArn)
        else:
            return PrivilegedSaResponse('','',privilegedRoleArn)

def delete_service_account(req: PrivilegedSaRequest):

    iam = boto3.client("iam")
    cf = boto3.client('cloudformation')
    stack_name = req.stack_name()

    logger.info(req)
    response=None
    try:
        response = iam.list_access_keys(
            UserName=req.sa_name(),
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchEntity':
            logger.warning("no access key exists")
        else:
            logger.error("Unexpected error: %s" % e)
    if response!=None:
        if response.get('ResponseMetadata').get('HTTPStatusCode')!=200:
            print("Error in list access keys, inspect: {}".format(response))
            return
        else:
            pprint.pprint(response)
            if len(response['AccessKeyMetadata'])==1:
                logger.info("delete access key")
                del_access_key_response = iam.delete_access_key(
                    UserName=req.sa_name(),
                    AccessKeyId=response['AccessKeyMetadata'][0]['AccessKeyId']
                )
                if del_access_key_response.get('ResponseMetadata').get('HTTPStatusCode')!=200:
                    print("Error in deleting access key id, inspect: {}".format(del_access_key_response))
                    return

    print(f"deleting stack: {stack_name}")
    try:
        cf.delete_stack(
            StackName=stack_name
        )
        waiter = cf.get_waiter('stack_delete_complete')
        waiter.wait(
            StackName=stack_name,
            WaiterConfig={
                'Delay': 10,
                'MaxAttempts': 12
            }
        )
    except ClientError as e:
        logger.error("Unexpected error: %s" % e)
        return

    response=None
    try:
        response = cf.describe_stacks(StackName=req.sa_trust_policy_stack_name())
    except ClientError as e:
        if e.response['Error']['Code'] == 'ValidationError':
            logger.warning(f"stack: {req.sa_trust_policy_stack_name()} does not exist")
        else:
            logger.error("Unexpected error: %s" % e)

    if response:
        print("trust policy stack details:")
        pprint.pprint(response)
        outputs = response.get('Stacks')[0].get('Outputs')
        saTrustPolicyArn=None
        if outputs !=None:
            for output in outputs:
                if output['OutputKey']=='SaTrustPolicyArn':
                    print("found: "+output['OutputKey'] + ': ' + output['OutputValue'])
                    saTrustPolicyArn=output['OutputValue']
                    logger.info(f"SA trust policy created: {saTrustPolicyArn}")

        if saTrustPolicyArn == None:
            logger.error("error in getting trust policy stack and get correct policy Arn")
            return

        try:
            detach_user_policy_result = iam.detach_user_policy(
                UserName=req.sa_name(),
                PolicyArn=saTrustPolicyArn
            )
        except ClientError as e:
            if e.response['Error']['Code'] == 'NoSuchEntity':
                logger.warning("user policy does not exist")
            else:
                logger.error("Unexpected error: %s" % e)

    print(f"deleting sa trust policy stack: {req.sa_trust_policy_stack_name()}")
    try:
        cf.delete_stack(
            StackName=req.sa_trust_policy_stack_name()
        )
        waiter = cf.get_waiter('stack_delete_complete')
        waiter.wait(
            StackName=req.sa_trust_policy_stack_name(),
            WaiterConfig={
                'Delay': 10,
                'MaxAttempts': 12
            }
        )
    except ClientError as e:
        logger.error("Unexpected error: %s" % e)
        return

    try:
        delete_user_result = iam.delete_user(
            UserName=req.sa_name()
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchEntity':
            logger.warning("user does not exist")
        else:
            logger.error("Unexpected error: %s" % e)

def lambda_handler(event, context):
    logger.info(f'Event: {event}. Context: {context}')

    try:
        operation = event.get('operation')
        ci_number = event.get('ci_number')
        aws_account_id = event.get('aws_account_id')
        role_name = event.get('role_name')
        cf_template_path = event.get('cf_template_path')

        sa_request=PrivilegedSaRequest(aws_account_id, ci_number, role_name, cf_template_path)

        logger.info(f'requested operation: {operation}')
        if operation == 'create_service_account':
            response=create_service_account(sa_request)
            masked_secret_key=''
            if response.secret_key!='':
                masked_secret_key='marked_secret_key'
            result=f"""access_key_id: {response.access_key_id}
                       secret_key: {response.masked_secret_key}
                       role_arn: {response.aws_role_arn}"""
            print(result)
        elif operation == 'delete_service_account':
            delete_service_account(sa_request)
        else:
            raise Exception("Operation not supported yet")
    except Exception as ex:
        ex_message = traceback.format_exc()
        logger.error(ex_message)
        raise ex

# For local testing purpose
if __name__ == "__main__":

    op=sys.argv[1]
    operation = "create_service_account" if op=="create" else "delete_service_account"

    test_mock_274330501474={
        'operation': operation,
        'aws_account_id': '274330501474',
        'ci_number': '12345678',
        'role_name': 'PAM-Super-Power-Role',
        'cf_template_path': 'roles/platform/test-privileged-role.yaml'
    }

    response = lambda_handler(
            test_mock_274330501474,
            "test"
        )
    print(response)
