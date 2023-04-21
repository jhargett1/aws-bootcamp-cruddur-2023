# Week 6 and 7  — Deploying Containers

We started these 2 weeks with the revelation that we're not going to be able to use ECS EC2, and instead will use Fargate. Andrew explained initially we were going to use ECS to stay away from spend for the bootcamp, but to stay within the free tier of EC2, it would require too much complexity and the spend incurred with Fargate is minimal. 

We began by making sure we can test our connection to the RDS. We created a new script file in '/backend-flask/db/' named test. 

```py
#!/usr/bin/env python3

import psycopg
import os
import sys

connection_url = os.getenv("CONNECTION_URL")

conn = None
try:
  print('attempting connection')
  conn = psycopg.connect(connection_url)
  print("Connection successful!")
except psycopg.Error as e:
  print("Unable to connect to the database:", e)
finally:
  conn.close()
```

After making the file executable running 'chmod u+x backend-flask/bin/db/test', we tested the script. 

![Week6Test](https://user-images.githubusercontent.com/119984652/230687179-8617e38f-3ace-41a1-928d-ef9762c4fd89.png)

We need to implement a health check endpoint into our app as well. We begin in the backend. In our 'app.py' file, we add a health check.

```py
@app.route('/api/health-check')
def health_check():
  return {'success': True}, 200
```
This will return a 200 status with a result of "success: True" if successful.

![image](https://user-images.githubusercontent.com/119984652/230687475-a6a02ec9-791e-4bc2-bfd0-4ae68671d447.png)

We then create a new folder and bin script at 'bin/flask/' named 'health-check' as well.

```py
#!/usr/bin/env python3

import urllib.request

try:
  response = urllib.request.urlopen('http://localhost:4567/api/health-check')
  if response.getcode() == 200:
    print("[OK] Flask server is running")
    exit(0) # success
  else:
    print("[BAD] Flask server is not running")
    exit(1) # false
# This for some reason is not capturing the error....
#except ConnectionRefusedError as e:
# so we'll just catch on all even though this is a bad practice
except Exception as e:
  print(e)
  exit(1) # false
```

Andrew informed us that we will also need a new AWS Cloudwatch group as well. We login to the AWS Console, then go to Cloudwatch, and view Logs > Log groups. Then back in our codespace, from the CLI, we create the log group.

```sh
aws logs create-log-group --log-group-name cruddur
aws logs put-retention-policy --log-group-name cruddur --retention-in-days 1
```

After running the command we refresh the AWS Cloudwatch console.

![image](https://user-images.githubusercontent.com/119984652/230689396-880156b7-0463-4098-920f-d5866fc1f3a3.png)

Now we must create our ECS cluster. Andrew explained we will do it through the CLI instead of the console because AWS changes their UI so frequently, there's no point in getting familiar with one layout. 

```sh
aws ecs create-cluster \
--cluster-name cruddur \
--service-connect-defaults namespace=cruddur
```

The '--service-connect-defaults' lets us set the name for the default Service Connect namespace to our cluster. It's a nicer way of mapping things internally using AWS Cloudmap. 

Again, back in the AWS console, only now in ECS, we now view Clusters.

![image](https://user-images.githubusercontent.com/119984652/230689845-60754c2c-a9ca-4ed1-ac0a-789a95044a52.png)

Andrew explains we're going to use AWS ECR to house our containers. To do this, we must first create a repository.

```sh
aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
```

This gives us a repository named 'cruddur-python' with the image tag being mutable. This will prevent tags from being overwritten. Next, we must login to ECR using our AWS credentials. The command here uses our env variables we've already set in our environment.

```sh
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```

We can now push containers. We set our path to the repo.

```sh
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"
```

We pull a version of Python for the container.

```sh
docker pull python:3.10-slim-buster
```

We then tag the image.

```sh
docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster
```

Next, we push the image.

```sh
docker push $ECR_PYTHON_URL:3.10-slim-buster
```

From ECR in the AWS console, we can now see our image in the repository.

![image](https://user-images.githubusercontent.com/119984652/230942977-689c623c-9da3-4a99-9f01-bcc06c050311.png)

Now we must update our Flask app to use this. We navigate to our 'backend-flask' location, then edit our Dockerfile.

```Dockerfile
FROM 554621479919.dkr.ecr.us-east-1.amazonaws.com/cruddur-python:3.10-slim-buster

#  Inside Container
# Make a new folder inside container
WORKDIR /backend-flask

# Outside Container -> Inside Container
# this contains the libraries we want to install to run the app
COPY requirements.txt requirements.txt

# Inside Container
# Install the python libraries used for the app
RUN pip3 install -r requirements.txt
```

To test the new configuration in our Dockerfile, we run select services from the cli. 

```sh
docker compose up backend-flask db
```

After this completes, we can see that the backend is running, as the port is now open. We test the health-check.

![image](https://user-images.githubusercontent.com/119984652/233216524-da7a2eac-d209-481a-ba80-cb17cba8dc08.png)

We can now start pushing this. So we again make another repo.

```sh
```sh
aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```

Next we set the URL:

```sh
export ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"
echo $ECR_BACKEND_FLASK_URL
```

Now we build the image. On our previous container, we didn't need to build an image, we pulled it. Andrew confirms we must make sure we're in the backend-flask directory prior to running the command.

```sh
docker build -t backend-flask .
```

We then tag and push the image.

```sh
docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest
```

We make sure to tag the push with the tag ':latest' although this isn't necessary. It will get tagged this way by default. Also when using AWS, Andrew explained it will always look for the ':latest' tag. 

```sh
docker push $ECR_BACKEND_FLASK_URL:latest
```

Before working on the frontend, Andrew explained he'd like us to get the backend going first, just to give us a basis of good debugging and understanding how these containers actually work.

From here, we go back to ECS in the AWS console. Andrew walks us through the UI of the existing options and configuration of setting up a service. While explaining task definitions, we find that the Cloudwatch log group we created earlier is improperly named. We neavigate back to Cloudwatch, and from the UI, we manually create a new log group named cruddur, with a retention period of 1 day. 

![image](https://user-images.githubusercontent.com/119984652/233219523-79937a4e-6c3d-4838-a1a3-d6d4f499613a.png)

Back in our code, we now need to finish creating our roles and setup the policy for our task definitions.

Our service-execution-policy.json followed by our service-assume-role-execution-policy.json:

```json
{
    "Version":"2012-10-17",
    "Statement":[{
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource": "arn:aws:ssm:us-east-1:554621479919:parameter/cruddur/backend-flask/*"        
    }]
}
```

```json
{
    "Version":"2012-10-17",
    "Statement":[{
      "Action":["sts:AssumeRole"],
      "Effect":"Allow",
      "Principal":{
        "Service":["ecs-tasks.amazonaws.com"]
      }}]
}
```

We run the files from the CLI to create the role and trust relationship in IAM.

```sh
aws iam create-role \
--role-name CruddurServiceExecutionRole \
--assume-role-policy-document file://aws/policies/service-assume-role-execution-policy.json
```

From the terminal, we can see they completed.

![image](https://user-images.githubusercontent.com/119984652/233491124-148f0326-7a41-4d65-a678-efde574e1b5f.png)


We also double-check from IAM in the AWS console to make sure the role is created.

![image](https://user-images.githubusercontent.com/119984652/233222461-61e96c00-dbb0-4249-8035-915239a10b2c.png)

The role policy was giving us issues, so we instead went through IAM in the AWS console to create it. We ended up created an inline policy for the CruddurExecutionRole we created previously.

![image](https://user-images.githubusercontent.com/119984652/233493685-3e9bb0bc-0aa5-4073-ba31-aa303a3a4765.png)

While in IAM, we check the trust relationship of the policy just created to make sure it created correctly as well:

![image](https://user-images.githubusercontent.com/119984652/233494869-706f893b-5f8f-4f47-8b74-8ab2c3f31351.png)

Moving back to the CLI, we create the task role named CruddurTaskRole:

```sh
aws iam create-role \
    --role-name CruddurTaskRole \
    --assume-role-policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[\"sts:AssumeRole\"],
    \"Effect\":\"Allow\",
    \"Principal\":{
      \"Service\":[\"ecs-tasks.amazonaws.com\"]
    }
  }]
}"
```

Then the policy for the role: 

```sh
aws iam put-role-policy \
  --policy-name SSMAccessPolicy \
  --role-name CruddurTaskRole \
  --policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[
      \"ssmmessages:CreateControlChannel\",
      \"ssmmessages:CreateDataChannel\",
      \"ssmmessages:OpenControlChannel\",
      \"ssmmessages:OpenDataChannel\"
    ],
    \"Effect\":\"Allow\",
    \"Resource\":\"*\"
  }]
}
"
```

We then grant the CruddurTaskRole full access to Cloudwatch and write access to the AWS XRay Daemon:

```sh
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurTaskRole
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess --role-name CruddurTaskRole
```

We can now begin working on our task definitions. From our workspace, we create a new folder from the aws directory named 'task-definitions' and then create a backend-flask.json file and a frontend-react-js.json file, filling in our own information.

```json
{
  "family": "backend-flask",
  "executionRoleArn": "arn:aws:iam::AWS_ACCOUNT_ID:role/CruddurServiceExecutionRole",
  "taskRoleArn": "arn:aws:iam::AWS_ACCOUNT_ID:role/CruddurTaskRole",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "backend-flask",
      "image": "BACKEND_FLASK_IMAGE_URL",
      "cpu": 256,
      "memory": 512,
      "essential": true,
      "portMappings": [
        {
          "name": "backend-flask",
          "containerPort": 4567,
          "protocol": "tcp", 
          "appProtocol": "http"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "cruddur",
            "awslogs-region": "us-east-1",
            "awslogs-stream-prefix": "backend-flask"
        }
      },
      "environment": [
        {"name": "OTEL_SERVICE_NAME", "value": "backend-flask"},
        {"name": "OTEL_EXPORTER_OTLP_ENDPOINT", "value": "https://api.honeycomb.io"},
        {"name": "AWS_COGNITO_USER_POOL_ID", "value": ""},
        {"name": "AWS_COGNITO_USER_POOL_CLIENT_ID", "value": ""},
        {"name": "FRONTEND_URL", "value": ""},
        {"name": "BACKEND_URL", "value": ""},
        {"name": "AWS_DEFAULT_REGION", "value": ""}
      ],
      "secrets": [
        {"name": "AWS_ACCESS_KEY_ID"    , "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/AWS_ACCESS_KEY_ID"},
        {"name": "AWS_SECRET_ACCESS_KEY", "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY"},
        {"name": "CONNECTION_URL"       , "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/CONNECTION_URL" },
        {"name": "ROLLBAR_ACCESS_TOKEN" , "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" },
        {"name": "OTEL_EXPORTER_OTLP_HEADERS" , "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" }
        
      ]
    }
  ]
}
```

```json
{
  "family": "frontend-react-js",
  "executionRoleArn": "arn:aws:iam::AWS_ACCOUNT_ID:role/CruddurServiceExecutionRole",
  "taskRoleArn": "arn:aws:iam::AWS_ACCOUNT_ID:role/CruddurTaskRole",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "frontend-react-js",
      "image": "BACKEND_FLASK_IMAGE_URL",
      "cpu": 256,
      "memory": 256,
      "essential": true,
      "portMappings": [
        {
          "name": "frontend-react-js",
          "containerPort": 3000,
          "protocol": "tcp", 
          "appProtocol": "http"
        }
      ],

      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "cruddur",
            "awslogs-region": "us-east-1",
            "awslogs-stream-prefix": "frontend-react"
        }
      }
    }
  ]
}
```

After this is completed, we register our task definitions from the CLI.

```sh
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/frontend-react-js.json
```

We next set a variable for after finding the default VPC in AWS by running this:

```sh
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```

We then use it to setup our security group:

```sh
export CRUD_SERVICE_SG=$(aws ec2 create-security-group \
  --group-name "crud-srv-sg" \
  --description "Security group for Cruddur services on ECS" \
  --vpc-id $DEFAULT_VPC_ID \
  --query "GroupId" --output text)
echo $CRUD_SERVICE_SG
```

Then authorize port 80 for the security group:

```sh
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_SERVICE_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

Next, we create our backend-flask service through ECS in the AWS console manually. From ECS it looks like there's an issue with our backend-flask cluster service. It's giving an error regarding the permissions to ECR and the logs:CreateLogStream action. So to fix this, we go back to IAM and edit the policy for our CruddurServiceExecutionPolicy.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:us-east-1:554621479919:parameter/cruddur/backend-flask/*"
        }
    ]
}
```

We go back to ECS and force a new deployment of our service. When we check the task itself, it's health status check came back as unknown. To troubleshoot the issue, we shelled into the task itself by running the following from CLI:

```sh
aws ecs execute-command \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task 99999999999999999999 \
--container backend-flask \
--command "/bin/bash" \
--interactive
```

Prior to this, we needed to install the Session Manager plugin for our CLI:

```sh
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"

sudo dpkg -i session-manager-plugin.deb
```

We're still unable to shell into the task. As it turns out, we need to enable an option for the service. This can only be done through the CLI, so we create a new file in our 'aws/json' directory named 'service-backend-flask.json' to create the service, with our own information:

```json
{
    "cluster": "cruddur",
    "launchType": "FARGATE",
    "desiredCount": 1,
    "enableECSManagedTags": true,
    "enableExecuteCommand": true,
    "loadBalancers": [
      {
          "targetGroupArn": "",
          "containerName": "backend-flask",
          "containerPort": 4567
      }
  ],
    "networkConfiguration": {
      "awsvpcConfiguration": {
        "assignPublicIp": "ENABLED",
        "securityGroups": [
          "sg-99999999999"
        ],
        "subnets": [
          "subnet-",
          "subnet-",
          "subnet-"
        ]
      }
    }
    "propagateTags": "SERVICE",
    "serviceName": "backend-flask",
    "taskDefinition": "backend-flask"
}
```

The '"enableExecuteCommand": true' option above is what we were needing to set. We relaunch the service, this time from the CLI:

```sh
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
```

We go back to ECS, grab the number from the recently started task, then again try to shell into the service task:

![image](https://user-images.githubusercontent.com/119984652/233505911-06db6ed8-9e55-44da-aa6e-c13fd2650cc2.png)


This time it works. We're able to perform a health check on the task:

```sh
./bin/flask/health-check
```

The health check returns saying the Flask server is running. When we go back to ECS, the task is showing healthy there as well. 

We create a new script for this process by creating a new folder in our 'backend-flask/bin' directory, named 'ecs', then a file inside named 'connect-to-service' where we copied the shell execute-command above into it. Then in our gitpod.yml file, to make sure Session Manager is installed in our environment at all times, we add a section for Fargate:

```yml
  - name: fargate 
    before: |
      cd /workspace
      curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
      sudo dpkg -i session-manager-plugin.deb 
      cd $THEIA_WORKSPACE_ROOT
      cd backend-flask
```

```sh
#! /usr/bin/bash
if [ -z "$1" ]; then
    echo "no TASK_ID argument supplied eg ./bin/ecs/connect-to-service 89a18169c70f41bd873e0395255291fa backend-flask"
    exit 1
fi
TASK_ID=$1

if [ -z "$2" ]; then
    echo "no CONTAINER_NAME argument supplied eg ./bin/ecs/connect-to-service 89a18169c70f41bd873e0395255291fa backend-flask"
    exit 1
fi
CONTAINER_NAME=$2

aws ecs execute-command \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task $TASK_ID \
--container $CONTAINER_NAME \
--command "/bin/bash" \
--interactive
```

From here, we go back to the AWS console, access EC2, then go to security groups. We must edit the inbound rules of our earlier created security group to open port 4567 for our backend-flask service to run. We also edit the default security group's inbound rules, this way our service can interact with our backend. 

![image](https://user-images.githubusercontent.com/119984652/233509371-2b170d69-ac6b-422b-99ef-5052f3431bc9.png)

Earlier when creating our service-backend-flask.json file, we had removed code that we reinsert now:

```json
    "serviceConnectConfiguration": {
      "enabled": true,
      "namespace": "cruddur",
      "services": [
        {
          "portName": "backend-flask",
          "discoveryName": "backend-flask",
          "clientAliases": [{"port": 4567}]
        }
      ]
    },
```

We again relaunch the service:

```sh
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
```

We now needed an application load balancer in place. We started by creating a new security group named cruddur-alb-sg. From there, edited the inbound rules of the crud-srv-sg security group to allow access for the ALB's security group as well. Then we created a new target group with a target of IP addresses named cruddur-backend-flask-tg and another for the frontend named frontend-react-js. Created application load balancer named cruddur-alb using the cruddur-alb-sg security group and the cruddur-backend-flask-tg and frontend-react-js target groups. 

![image](https://user-images.githubusercontent.com/119984652/233512250-78b895e8-2792-42db-b9f0-e4e815ed02db.png)

In reviewing our frontend-react-js.json file, we decide we need to make a separate Dockerfile for production. We navigate to our frontend-react-js folder in our workspace, then created 'Dockerfile.prod'

```dockerfile
# Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM node:16.18 AS build

ARG REACT_APP_BACKEND_URL
ARG REACT_APP_AWS_PROJECT_REGION
ARG REACT_APP_AWS_COGNITO_REGION
ARG REACT_APP_AWS_USER_POOLS_ID
ARG REACT_APP_CLIENT_ID

ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL
ENV REACT_APP_AWS_PROJECT_REGION=$REACT_APP_AWS_PROJECT_REGION
ENV REACT_APP_AWS_COGNITO_REGION=$REACT_APP_AWS_COGNITO_REGION
ENV REACT_APP_AWS_USER_POOLS_ID=$REACT_APP_AWS_USER_POOLS_ID
ENV REACT_APP_CLIENT_ID=$REACT_APP_CLIENT_ID

COPY . ./frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
RUN npm run build

# New Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM nginx:1.23.3-alpine

# --from build is coming from the Base Image
COPY --from=build /frontend-react-js/build /usr/share/nginx/html
COPY --from=build /frontend-react-js/nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000
```

For the above file to work, we must also implement an nginx.conf or configuration file. 

```js
# Set the worker processes
worker_processes 1;

# Set the events module
events {
  worker_connections 1024;
}

# Set the http module
http {
  # Set the MIME types
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  # Set the log format
  log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

  # Set the access log
  access_log  /var/log/nginx/access.log main;

  # Set the error log
  error_log /var/log/nginx/error.log;

  # Set the server section
  server {
    # Set the listen port
    listen 3000;

    # Set the root directory for the app
    root /usr/share/nginx/html;

    # Set the default file to serve
    index index.html;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to redirecting to index.html
        try_files $uri $uri/ $uri.html /index.html;
    }

    # Set the error page
    error_page  404 /404.html;
    location = /404.html {
      internal;
    }

    # Set the error page for 500 errors
    error_page  500 502 503 504  /50x.html;
    location = /50x.html {
      internal;
    }
  }
}
```

The nginx.conf file in the Dockerfile is used to configure the Nginx web server that is being used to serve the static content generated by our React application. The configuration file sets up the server to listen on port 3000 and serve the static files located in the /usr/share/nginx/html directory. It also sets up error pages and logging.

The location / block in the configuration file is particularly important as it specifies how Nginx will handle incoming requests. In this case, it uses the try_files directive to first attempt to serve the request as a file, then as a directory, and finally fallback to redirecting to index.html. 

We cd into our frontend-react-js directory, then do an 'npm run build'. We're now told from the terminal that our build folder is ready to be deployed. 

We build the image for the frontend from CLI:

```sh
docker build \
--build-arg REACT_APP_BACKEND_URL="https://4567-$GITPOD_WORKSPACE_ID.$GITPOD_WORKSPACE_CLUSTER_HOST" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="us-east-1_99999999" \
--build-arg REACT_APP_CLIENT_ID="9999999999999999" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```

We also have to create our repository for the frontend still:

```sh
aws ecr create-repository \
--repository-name frontend-react-js \
--image-tag-mutability MUTABLE
```

We set the URL, then tag and push the Docker image.

```sh
export ECR_FRONTEND_REACT_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/frontend-react-js"
echo $ECR_FRONTEND_REACT_URL
```

```sh
docker tag frontend-react-js:latest $ECR_FRONTEND_REACT_URL:latest
```

```sh
docker push $ECR_FRONTEND_REACT_URL:latest
```

We now decide to create our frontend-react-js service. To do so, from our 'aws/json' folder, we create a new file named 'service-frontend-react-js.json'

```json
{
    "cluster": "cruddur",
    "launchType": "FARGATE",
    "desiredCount": 1,
    "enableECSManagedTags": true,
    "enableExecuteCommand": true,
    "loadBalancers": [
      {
          "targetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:99999999999:targetgroup/cruddur-frontend-react-js/9999999999999",
          "containerName": "frontend-react-js",
          "containerPort": 3000
      }
  ],        
    "networkConfiguration": {
      "awsvpcConfiguration": {
        "assignPublicIp": "ENABLED",
        "securityGroups": [
          "sg-9999999999999"
        ],
        "subnets": [
            "subnet-",
            "subnet-",
            "subnet-"
          ]
      }
    },
    "propagateTags": "SERVICE",
    "serviceName": "frontend-react-js",
    "taskDefinition": "frontend-react-js",
    "serviceConnectConfiguration": {
      "enabled": true,
      "namespace": "cruddur",
      "services": [
        {
          "portName": "frontend-react-js",
          "discoveryName": "frontend-react-js",
          "clientAliases": [{"port": 3000}]
        }
      ]
    }
  }
```

