import os
import boto3
import json
from requests_oauthlib import OAuth2Session
import urllib3

client_id = os.getenv("CLIENT_ID")
client_secret = os.getenv("CLIENT_SECRET")
dynamo_db_table_name = os.getenv("DYNAMO_DB_TABLE_NAME")
authorization_base_url = 'https://github.com/login/oauth/authorize'
token_url = 'https://github.com/login/oauth/access_token'
scope = ["read:org openid user:email read:user"]
github_org = os.getenv("GITHUB_ORG")
ssm_path_invoke_url = os.getenv("SSM_PATH_INVOKE_URL")

def handler(event, context):
    ### Check oAuth2 state
    dynamodb_client = boto3.client('dynamodb')
    ssm_client = boto3.client('ssm')

    redirect_uri = ssm_client.get_parameter(
        Name=ssm_path_invoke_url,
        WithDecryption=False
    )['Parameter']['Value']

    dynamodb_item = dynamodb_client.get_item(
        TableName=dynamo_db_table_name,
        Key={
            'state': {
                'S': event['queryStringParameters']['state']
            }
        },
        ConsistentRead=False,
        ReturnConsumedCapacity='NONE')
    ### if state found in dynamodb
    if 'Item' in dynamodb_item:
        oauth = OAuth2Session(client_id=client_id, redirect_uri=redirect_uri)
        try:
            token = oauth.fetch_token(token_url=token_url, code=event['queryStringParameters']['code'],
                                      client_secret=client_secret)
        except Exception as exception:
            return {
                "isAuthorized": False,
                "context": {
                    "error": str(exception)
                }
            }

        http = urllib3.PoolManager()
        token_str = 'token {}'.format(token['access_token'])
        try:
            user = http.request(
                'GET',
                'https://api.github.com/user',
                headers={
                    'Accept': 'application/json',
                    'Authorization': token_str
                }
            )
        except Exception as e:
            return {
                "isAuthorized": False,
                "context": {
                    "error": str(e)
                }
            }
        user_login = json.loads(user.data)['login']
        check_membership_url = "https://api.github.com/orgs/" + github_org + "/members/" + user_login
        try:
            is_member = http.request(
                'GET',
                check_membership_url,
                headers={
                    'Accept': '*/*',
                    'Authorization': token_str
                })
        except Exception as e:
             return {
                "isAuthorized": False,
                "context": {
                    "error": str(e)
                }
            }
        print("membership status: {}, if not 204 user is not a member of organization".format(is_member.status))
        if is_member.status == 204:
            return {
                "isAuthorized": True,
                "context": {
                    "Membership": github_org
                }
            }

    return {
        "isAuthorized": False,
        "context": {
            "Membership": "not confirmed"
        }
    }
