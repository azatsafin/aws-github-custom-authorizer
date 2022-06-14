# GitHub Custom AWS Lambda authorizer 

It is a boundle of Terraform module and Lambda functions source code
It allow to Invoke Lambda function if user passed GitHub authentication and it is a member of specific GitHub organization
## How it works
The output of the module is authentication url, when user open it, it will be redirected to Hithub authentication page. When user passed authentification it will be redirected back with the oAuth code. Module exchange Github code to access_token,  then module use token to get user details and check user membership in organization by calling GitHub API. If user is a member of organization lambda custom authorizer allow to Invoke your Lambda function. Also it pass output of https://docs.github.com/en/rest/users/users#get-the-authenticated-user to the executable lambda.  You can found it in destination Lambda at ```event['requestContext']['authorizer']['lambda']``` dict object.
## How it could be used
In our organization we use it to return the data stored in AWS SSM params. Executable Lambda determine what value of SSM Param will be returned to user if if pass verification. 

### How to deploy
You could install it manually or by provided terraform module under ==terraform== directory. 
The deployment example under ==test-deployment== directory.

### Diagram
![diagram](https://lucid.app/publicSegments/view/f8d3ec1f-f82a-4a59-bd89-5be1341a78cd/image.png).

