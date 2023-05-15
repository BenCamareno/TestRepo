
# flake8: noqa

import json
import logging
import requests
import os
import re
from urllib.parse import urlsplit, urlunsplit, urljoin
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError
from github import Github

# Set logger
logger = logging.getLogger()
if "DEBUG" in os.environ:
    logger.setLevel(logging.DEBUG)
else:
    logger.setLevel(logging.INFO)

SUCCESS = "SUCCESS"
FAILED = "FAILED"


def cfnresponse_send(
    event, context, responseStatus, responseData, physicalResourceId=None, noEcho=False
):
    responseUrl = event["ResponseURL"]

    print(responseUrl)

    responseBody = {}
    responseBody["Status"] = responseStatus
    responseBody["Reason"] = (
        "See the details in CloudWatch Log Stream: " + context.log_stream_name
    )
    responseBody["PhysicalResourceId"] = physicalResourceId or context.log_stream_name
    responseBody["StackId"] = event["StackId"]
    responseBody["RequestId"] = event["RequestId"]
    responseBody["LogicalResourceId"] = event["LogicalResourceId"]
    responseBody["NoEcho"] = noEcho
    responseBody["Data"] = responseData

    json_responseBody = json.dumps(responseBody)

    print("Response body:\n" + json_responseBody)

    headers = {"content-type": "", "content-length": str(len(json_responseBody))}

    try:
        response = requests.put(responseUrl, data=json_responseBody, headers=headers)
        print("Status code: " + response.reason)
    except Exception as e:
        print("send(..) failed executing requests.put(..): " + str(e))


def get_cb_client():
    """Creates and return a codebuild client using boto3"""
    return boto3.client("codebuild")


def get_ghe_token():
    """Returns GitHub token configured for CI/CD."""
    client = boto3.client("secretsmanager")
    secret_name = os.environ["GITHUB_TOKEN_SECRET_NAME"]
    return client.get_secret_value(SecretId=secret_name)["SecretString"]


def get_ghe_client(gheUrl):
    """Creates and returns a GHE client using pyGitHub"""
    repo_url_split = urlsplit(gheUrl)
    ghe_base_url = "{0.scheme}://{0.netloc}/".format(repo_url_split)
    repo_name = re.sub("\.git$", "", repo_url_split.path)[1:]

    token = get_ghe_token()

    g = Github(
        base_url=urljoin(ghe_base_url, "api/v3"), verify=False, login_or_token=token
    )
    repo = g.get_repo(repo_name)
    return repo


def get_payload_url(payloadUrl):
    """substitute codebuild endpoint url with a custom one"""
    if "CodeBuildDNSRecord" in os.environ:
        normalUrl = urlsplit(payloadUrl)
        payloadUrl = urlunsplit(
            normalUrl[:1] + (os.environ["CodeBuildDNSRecord"],) + normalUrl[2:]
        )
    return payloadUrl


def get_webhook_config(payloadUrl, payloadSecret):
    """generate a GHE webhook config"""
    config = {
        "url": "{}".format(payloadUrl),
        "content_type": "json",
        "secret": "{}".format(payloadSecret),
        "insecure_ssl": "1",
    }
    return config


def create(cb_client, cb_projectName, cb_filterGroups, gh_client):
    """Create a webhook"""
    responseData = {}
    cb_webhook = cb_client.create_webhook(
        projectName=cb_projectName, filterGroups=cb_filterGroups
    )

    payloadUrl = get_payload_url(cb_webhook["webhook"]["payloadUrl"])
    responseData = gh_client.create_hook(
        name="web",
        config=get_webhook_config(payloadUrl, cb_webhook["webhook"]["secret"]),
        events=["push", "pull_request"],
        active=True,
    )
    return (
        {"id": responseData.id, "url": responseData.url},
        "{}/hooks/{}".format(gh_client.full_name, responseData.id),
    )


def update(cb_client, cb_projectName, cb_filterGroups, gh_client, resource_id):
    """Update webhook"""
    cb_webhook = cb_client.update_webhook(
        projectName=cb_projectName, filterGroups=cb_filterGroups
    )
    hook_id = int(resource_id.split("/")[-1])
    hook = gh_client.get_hook(hook_id)
    if "payloadUrl" in cb_webhook["webhook"] and "secret" in cb_webhook["webhook"]:
        payloadUrl = get_payload_url(cb_webhook["webhook"]["payloadUrl"])
        hook.edit(
            name="web",
            config=get_webhook_config(payloadUrl, cb_webhook["webhook"]["secret"]),
            events=["push", "pull_request"],
            active=True,
        )
    return (
        {"id": hook.id, "url": hook.url},
        "{}/hooks/{}".format(gh_client.full_name, hook.id),
    )


def delete(cb_client, cb_projectName, gh_client, resource_id):
    """Delete webhook"""
    try:
        cb_client.delete_webhook(projectName=cb_projectName)
    except Exception as e:
        logging.error("Error: %s", str(e))

    hook_id = int(resource_id.split("/")[-1])
    hook = gh_client.get_hook(hook_id)
    hook.delete()
    return ({}, "{}/hooks/{}".format(gh_client.full_name, hook.id))


def lambda_handler(event, context):
    """Main lambda handler"""
    responseData = {}
    physicalResourceId = ""
    try:
        logger.debug(json.dumps(event))

        if event["RequestType"] == "Create":
            responseData, physicalResourceId = create(
                get_cb_client(),
                event["ResourceProperties"]["projectName"],
                event["ResourceProperties"]["filterGroups"],
                get_ghe_client(event["ResourceProperties"]["gheUrl"]),
            )

        elif event["RequestType"] == "Update":
            responseData, physicalResourceId = update(
                get_cb_client(),
                event["ResourceProperties"]["projectName"],
                event["ResourceProperties"]["filterGroups"],
                get_ghe_client(event["ResourceProperties"]["gheUrl"]),
                event["PhysicalResourceId"],
            )

        elif event["RequestType"] == "Delete":
            responseData, physicalResourceId = delete(
                get_cb_client(),
                event["ResourceProperties"]["projectName"],
                get_ghe_client(event["ResourceProperties"]["gheUrl"]),
                event["PhysicalResourceId"],
            )

        else:
            raise Exception()

        cfnresponse_send(event, context, SUCCESS, responseData, physicalResourceId)
    except Exception as e:
        logging.error("Error: %s", str(e))
        if "PhysicalResourceId" in event:
            cfnresponse_send(
                event, context, FAILED, responseData, event["PhysicalResourceId"]
            )
        else:
            cfnresponse_send(event, context, FAILED, responseData)
        raise e
