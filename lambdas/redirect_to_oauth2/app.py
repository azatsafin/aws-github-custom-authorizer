import os
import boto3
import json
import logging
import time

from requests_oauthlib import OAuth2Session

client_id = os.getenv("CLIENT_ID")
client_secret = os.getenv("CLIENT_SECRET")
dynamo_db_table_name = os.getenv("DYNAMO_DB_TABLE_NAME")
authorization_base_url = 'https://github.com/login/oauth/authorize'
scope = ["read:org openid user:email read:user"]
ssm_path_invoke_url = os.getenv("SSM_PATH_INVOKE_URL")

def handler(event, context):
    ssm_client = boto3.client('ssm')
    redirect_uri = ssm_client.get_parameter(
        Name=ssm_path_invoke_url,
        WithDecryption=False
    )['Parameter']['Value']

    oauth = OAuth2Session(client_id, redirect_uri=redirect_uri,
                          scope=scope)
    authorization_url, state = oauth.authorization_url(authorization_base_url)
    dynamodb_client = boto3.client('dynamodb')
    dynamodb_client.put_item(
        TableName=dynamo_db_table_name,
        Item={
            'state': {'S': state},
            'ttl': {'N': str(int(time.time() + 2*3600))}
        })

    return {
        "statusCode": 301,
        "headers": {
            "Location": authorization_url,
            "Cache-Control": "max-age=3600"
        }
    }
