# Week 6 and 7  — Deploying Containers

We started these 2 weeks with the revelation that we're not going to be able to use ECS, and instead will use Fargate. Andrew explained initially we were going to use ECS to stay away from spend for the bootcamp, but to stay within the free tier of EC2, it would require too much complexity and the spend incurred with Fargate is minimal. 

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
        {"name": "FRONTEND_URL", "value": "*"},
        {"name": "BACKEND_URL", "value": "*"},
        {"name": "AWS_DEFAULT_REGION", "value": "us-east-1"}
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

We can now create the service from the CLI:

```sh
aws ecs create-service --cli-input-json file://aws/json/service-frontend-react-js.json
```

Back in ECS, the service deploys a task, but the task shows unhealthy in the logs. We stop the task from the AWS console, then go back our workspace. We edit the code for our frontend-react-js.json file, removing the load balancer so we can get into the task to troubleshoot.

Code removed:

```json
    "loadBalancers": [
      {
          "targetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:99999999999:targetgroup/cruddur-frontend-react-js/9999999999999",
          "containerName": "frontend-react-js",
          "containerPort": 3000
      }
```

We create the service from the CLI again, running the cmd from above. we next run one of our bash scripts to connect to the service.

```sh
./bin/ecs/connect-to-service _9999999999_ frontend-react-js
```

This fails.

![image](https://user-images.githubusercontent.com/119984652/233735020-2e4ccb4d-c08c-47c2-afa1-a100fe1aeadf.png)

We decide to rebuild the production environment locally to troubleshoot.

```sh
docker build \
--build-arg REACT_APP_BACKEND_URL="https://4567-$GITPOD_WORKSPACE_ID.$GITPOD_WORKSPACE_CLUSTER_HOST" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="us-east-1_99999999999" \
--build-arg REACT_APP_CLIENT_ID="9999999999999" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```

Then we run it:

```sh
docker run --rm -p 3000:3000 -it frontend-react-js
```

We find that since the container is running in Alpine, it does not have the ability to allow us to shell into it, as it's not installed by default for the container. Instead we duplicate our connect-to-service script we created earlier, and specify each file, one for connect-to-backend-flask and the other connect-to-frontend-react.

```sh
#! /usr/bin/bash
if [ -z "$1" ]; then
    echo "no TASK_ID argument supplied eg ./bin/ecs/connect-to-frontend-react-js 89a18169c70f41bd873e0395255291fa"
    exit 1
fi
TASK_ID=$1

CONTAINER_NAME=frontend-react-js

aws ecs execute-command \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task $TASK_ID \
--container $CONTAINER_NAME \
--command "/bin/sh" \
--interactive
```

```sh
#! /usr/bin/bash
if [ -z "$1" ]; then
    echo "no TASK_ID argument supplied eg ./bin/backend/connect-to-backend-flask 89a18169c70f41bd873e0395255291fa"
    exit 1
fi
TASK_ID=$1

CONTAINER_NAME=backend-flask

aws ecs execute-command \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task $TASK_ID \
--container $CONTAINER_NAME \
--command "/bin/bash" \
--interactive
```

After chmod'ing both files, we run 'connect-to-frontend-react-js'

```sh
./bin/ecs/connect-to-frontend-react-js <taskid>
```

This connection is successful. We find that we have curl, so Andrew asks ChatGPT to write a curl for a health check on a task definition running in Fargate. In the generated code, we find the health check, and add it to our 'frontend-react-js.json' file. 

```json
"healthCheck": {
  "command": [
    "CMD-SHELL",
    "curl -f http://localhost:3000 || exit 1"
    ],
    "interval": 30,
    "timeout": 5,
    "retries": 3
    }
}
```

After this, we re-register our task definition for 'frontend-react-js.json'

```sh
aws ecs register-task=definition --cli-input-json file://aws/task-definitions/frontend-react-js.json
```

We go into EC2 in the AWS Console and check the target group for the frontend. In reviewing the health check, we find we may need to override the port to port 3000, so we do so. 

Back in our workspace, we go back into our 'service-frontend-react-js.json' file and add our Load Balancer code back in to test and see if the port override on the target group was the issue. 

```json
    "loadBalancers": [
      {
          "targetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:99999999999:targetgroup/cruddur-frontend-react-js/9999999999999",
          "containerName": "frontend-react-js",
          "containerPort": 3000
      }
```

We then create the service again, after removing the service from ECS:

```sh
aws ecs create-service --cli-input-json file://aws/json/service-frontend-react-js.json
```

In reviewing the target from target groups in EC2, the target shows a status of unhealthy because the request timed out. We review our service security group we setup previously and find that we hadn't setup port information for the frontend yet. We edit the inbound rules, allowing port 3000. We go back into our target groups and remove the port override, then check the status of our service. It now shows a healthy task! 

Moving forward, we now decide to setup our custom domain. We open Route53 in AWS, then go to Hosted Zones. We create a new hosted zone using our custom domain we purchased prior to the bootcamp. I added thejoshdev.com. Next, we needed an SSL certificate, so we went to AWS Certificate Manager > Request a certificate > Request a public certificate. I entered my FQDN, then added a wildcard, and asked for DNS validation.

My certificate was pending validation, even when Andrew's completed. I still needed to update my DNS settings on my domain registrar to use the AWS nameservers setup in Route53. I updated this, then waited over the weekend for the change to propagate. When I returned to Certificate Manager, my domains showed a success status.

![image](https://user-images.githubusercontent.com/119984652/233741490-1c93e322-45dd-4da1-a914-a7a326b1235d.png)

Back in Route53, we now have a CNAME record added. We move over to EC2, then select our load balancer. From there, we edit the listeners. We set the frontend listener on port 80 to forward to port 443 for https. Next, we set another rule, forwarding port 443 to our cruddur-frontend-react-js target group.

![image](https://user-images.githubusercontent.com/119984652/233742524-caea5cc2-7361-4ca3-99ec-5f2321257678.png)

We then remove our previously setup listeners on port 3000 and 4567. 

![image](https://user-images.githubusercontent.com/119984652/233742625-9cab7914-0287-4e8b-97e5-22a84ab72444.png)

We go back into our listener for port 443, editing the rule. Host header is api.thejoshdev.com, then forward to cruddur-backend-flask target group. Back in Route53, we go back to Hosted Zones and create a new record. Its an A record, routing traffic to "Alias to Application and Classic Load Balancer" in us-east-1 using our ALB load balancer. The routing policy is set to simple, then we save it. Next we create another A record, all of the same settings as before, but this time we create a subdomain of `api` to thejoshdev.com. Since we hae this, it's decided we do not need the added routing of /api/ when reaching our health-check, so we go back into our workspace. We open our app.py file, and update our @app.routes to remove the /api/ from the path. 

From this:
![image](https://user-images.githubusercontent.com/119984652/233745591-4bd713fc-d215-49e7-9bcd-e8422dc74720.png)

To this:
![image](https://user-images.githubusercontent.com/119984652/233745624-5582830f-1e4a-4a2f-99e3-ee61fdd2d690.png)

We started to clean up the remaining @app.routes, but Andrew recalled we will need these from the frontend, so we instead go back and revert these changes. Instead we go into our task-definitions folder, then select our backend-flask.json file and edit the ennironment variables for "FRONTEND_URL" and "BACKEND_URL".

```json
          {"name": "FRONTEND_URL", "value": "thejoshdev.com"},
          {"name": "BACKEND_URL", "value": "api.thejoshdev.com"},
```

With this change, we now have to go and update our task definition from the CLI to make the change in ECS:

```sh
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
```

We now have to push the image for the frontend-react again. We make sure we're still logged into ECR first:

```sh
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```

We edit our build a bit, changing the variable for REACT_APP_BACKEND_URL to reflect our new subdomain, then build it.

We first set the URL.

```sh
export ECR_FRONTEND_REACT_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/frontend-react-js"
echo $ECR_FRONTEND_REACT_URL
```

Then build.

```sh
docker build \
--build-arg REACT_APP_BACKEND_URL="https://api.cruddur.com" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="us-east-1_99999999999" \
--build-arg REACT_APP_CLIENT_ID="9999999999999" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```

We tag and push the image.

```sh
docker tag frontend-react-js:latest $ECR_FRONTEND_REACT_URL:latest

docker push $ECR_FRONTEND_REACT_URL:latest
```

With the task definitions for the backend updated, we go back to ECS and update the service, forcing a new deployment, using the latest revision. The frontend uses the latest revision by default, so all we need to do is update the service, forcing a new deployment. Both tasks show as healthy after deployment, so we go check our target groups in ec2 > Target Groups > both the frontend and backend are now showing as healthy. 

![image](https://user-images.githubusercontent.com/119984652/233783090-a4199ff6-a1c8-43e9-992d-5b6b7f845ebc.png)

When we load the app through the browser, it displays. However there's no data returned, also if we inspect it, there's a CORS error for the subdomain, api.thejoshdev.com. Andrew is getting the same for api.cruddur.com. We go back into ECS and grab the task id for the backend task. Then, back in our workspace, we use our script to connect to it.

```sh
./bin/ecs/connect-to-backend-flask <taskid>
```

Once in the task, we type `env` to see what environment variables are set.

![image](https://user-images.githubusercontent.com/119984652/233783448-4f8d3d36-02ef-4512-b5a9-90bbcb66e310.png)

After scrolling up, we see that the FRONTEND_URL and BACKEND_URL are being set. But they do not have protocols being set, so we again go back to our backend-flask.json task definition file and edit the variables for FRONTEND_URL AND BACKEND_URL.

```json
          {"name": "FRONTEND_URL", "value": "https://thejoshdev.com"},
          {"name": "BACKEND_URL", "value": "https://api.thejoshdev.com"},
```

We again register the task definitions through the CLI, then force a new deployment through ECS. After waiting several moments for the new deployement, we can test the app again, and it's now returning data! 

In investigating our app now that it's deployed, we ran into some debugging menus that we need to remove once we're in a production mode environment. Andrew finds documentation online regarding debugging application errors in production [here:](https://flask.palletsprojects.com/en/2.2.x/debugging/). We found that with debugging enabled in a production environment, "The debugger allows executing arbitrary Python code from the browser."

Upon learning this, we navigate in AWS  over to EC2 and the security group for our load balancer. We edit the inbound rules, removing the open ports for 3000 and 4657, then for the time being, only allow `My IP` from both protocols HTTPS and HTTP and their respective ports, 443 and 80. This will lock the app down to where only I can access it for the time being. 

Back in our workspace, we navigate to our `backend-flask` folder, select our Dockerfile and edit it, adding `--debug` to our CMD. This allows debugging in our development:

```Dockerfile
# CMD (Command)
# python3 -m flask run --host=0.0.0.0 --port=4567
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567", "--debug"]
```

Then we create a new Dockerfile, `Dockerfile.prod`. This will be for production. Notice the flags on our CMD are slightly different than our development Dockerfile:

```dockerfile
FROM 99999999999.dkr.ecr.us-east-1.amazonaws.com/cruddur-python:3.10-slim-buster

# [TODO] For debugging, don't leave these in
#RUN apt-get update -y
#RUN apt-get install iputils-ping -y
# -------

#  Inside Container
# Make a new folder inside container
WORKDIR /backend-flask

# Outside Container -> Inside Container
# this contains the libraries we want to install to run the app
COPY requirements.txt requirements.txt

# Inside Container
# Install the python libraries used for the app
RUN pip3 install -r requirements.txt

# Outside Container -> Inside Container
# . means everything in the current directory
# first period . - /backend-flask (outside container)
# second period ./backend-flask (inside container)
COPY . .

EXPOSE ${PORT}

# CMD (Command)
# python3 -m flask run --host=0.0.0.0 --port=4567
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567", "--no-debug", "--no-debugger", "--no-reload"]
```

To build our production Dockerfile separately, we go to the CLI. First we login to ECR again:

```sh
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```

With logging into the ECR being such a repetitive task, we decide to create a script for it. From our `backend-flask/bin` folder, we create a new folder named `ecr` then a new file named `login`. 

```sh
#! /usr/bin/bash

aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```

After chmod'ing the file, it's executable. We run the file, then proceed with building our production Dockerfile.

```sh
./bin/ecr/login


docker build -f Dockerfile.prod -t backend-flask-prod .
```

To test this production build, we have to run the Dockerfile, passing our environment variables to it.

```sh
#! /usr/bin/bash

docker run --rm \
-p 4567:4567 \
--env AWS_ENDPOINT_URL="http://dynamodb-local:8000" \
--env CONNECTION_URL="postgresql://postgres:***************@db:5432/cruddur" \
--env FRONTEND_URL="https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}" \
--env BACKEND_URL="https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}" \
--env OTEL_SERVICE_NAME='backend-flask' \
--env OTEL_EXPORTER_OTLP_ENDPOINT="https://api.honeycomb.io" \
--env OTEL_EXPORTER_OTLP_HEADERS="x-honeycomb-team=${HONEYCOMB_API_KEY}" \
--env AWS_XRAY_URL="*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*" \
--env AWS_XRAY_DAEMON_ADDRESS="xray-daemon:2000" \
--env AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}" \
--env AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
--env AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
--env ROLLBAR_ACCESS_TOKEN="${ROLLBAR_ACCESS_TOKEN}" \
--env AWS_COGNITO_USER_POOL_ID="${AWS_COGNITO_USER_POOL_ID}" \
--env AWS_COGNITO_USER_POOL_CLIENT_ID="99999999999999999" \
-it backend-flask-prod
```

Before running this, we save it to a new folder in our `bin` directory, naming it `docker/backend-flask-prod`. We make the file executable by chmod'ing it, then run it. 

![image](https://user-images.githubusercontent.com/119984652/233786447-a2f00f4b-f8a9-4618-89e2-653a45b9ee58.png)

We get connection pool errors from the console, but this is because our PostgreSQL db is not running in the current environment, so we do a docker compose up on selective services, select our `db` then let it compose up.

![image](https://user-images.githubusercontent.com/119984652/233786463-3787ecd7-7a30-430e-813c-64d5ec92828a.png)

We're still having connections issues to the database, but that's not what we're concerned with here. We're trying to see if errors are logged in debug mode, so instead we go to our `app.py` file and introduce an error in the health-check. Then we go back and create a new folder within our `backend-flask/docker` folder named `build` then create two new files `backend-flask-prod` and `frontend-react-js-prod`. 

```sh
#! /usr/bin/bash

docker build -f Dockerfile.prod -t backend-flask-prod .

```

```sh
#! /usr/bin/bash

docker build \
--build-arg REACT_APP_BACKEND_URL="https://4567-$GITPOD_WORKSPACE_ID.$GITPOD_WORKSPACE_CLUSTER_HOST" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="us-east-1_9999999" \
--build-arg REACT_APP_CLIENT_ID="999999999999999" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```

We then spin up our environment with the regular Dockerfile from the backend. With our non-production environment now running, we launch the backend of our app from our workspace, then modify the URL to direct to our health-check, adding `/api/health-check` to the end of our URL. The page returns a TypeError, due to the error we introduced earlier.

![image](https://user-images.githubusercontent.com/119984652/233787410-88541b51-274c-403d-b208-eb9ab1197b55.png)

Since we don't want to see the TypeError page, we test modifying the CMD from our Dockerfile. 

```Dockerfile
CMD [ "python3, "-m" , "flask, "run", "--host=0.0.0.0", "--port=4567", "--no-debug"]
```

We then compose up our environment again. Once it loads, we again launch our backend and modify the URL to direct to our health-check, which we introduced an error into previously.

![image](https://user-images.githubusercontent.com/119984652/233787664-93bc22dc-c711-45a8-a8a6-31e15ab5da11.png)

It now returns an Internal Server Error page, which means the flag we passed in our development Dockerfile worked. It's not in debug mode. We modify the development Dockerfile back, removing the `--no-debug` flag from the CMD. 

We now chmod our two files we created earlier in the `docker` folder to make them exectuable. Then, we run the `backend-flask-prod` file to build the production environment again.

```sh
./bin/docker/build/backend-flask-prod
```

We create another script and folder, this time from the `docker` directory, a `push` folder, with a file named `backend-flask-prod`, then chmod the file.

```sh
#! usr/bin/bash

ECR_FRONTEND_REACT_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/frontend-react-js"
echo $ECR_FRONTEND_REACT_URL
docker tag backend-flask-prod:latest $ECR_BACKEND_FLASK_URL:latest
docker push $ECR_BACKEND_FLASK_URL:latest
```

We run this file, and it tags and pushes the image. Instead of manually running all of these commands from the CLI, we decide to simplify things and begin working on creating scripts for all of this. In our `ecs` folder created previously, we create a new file `force-deploy-backend-flask`. Our goal with this file is to force a new deployment of the backend-flask service from ECS. 

```sh

#! /usr/bin/bash

CLUSTER_NAME="cruddur"
SERVICE_NAME="backend-flask"
TASK_DEFINITION_FAMILY="backend-flask"

LATEST_TASK_DEFINITION_ARN=$(aws ecs describe-task-definition \
--task-definition $TASK_DEFINITION_FAMILY \
--query 'taskDefinition.taskDefinitionArn' \
--output text)

echo "TASK DEF ARN:"
echo $LATEST_TASK_DEFINITION_ARN

aws ecs update-service \
--cluster $CLUSTER_NAME \
--service $SERVICE_NAME \
--task-definition $LATEST_TASK_DEFINITION_ARN \
--force-new-deployment
```

We were running into issues with pathing in our scripts, as we are now moving them to new directories, and additional folders have been created/removed. We moved the `/bin/` directory to the root of our workspace. A fellow bootcamper reached out to Andrew with a possible solution to the problem getting us the absolute path and implementing it into our scripts. We start with the `frontend-react-js-prod` script from earlier.

```sh
#! /usr/bin/bash 

ABS_PATH=$(readlink -f "$0")
BUILD_PATH=$(dirname $ABS_PATH)
DOCKER_PATH=$(dirname $BUILD_PATH)
BIN_PATH=$(dirname $DOCKER_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
FRONTEND_REACT_JS_PATH="$PROJECT_PATH/frontend-react-js"

docker build \
--build-arg REACT_APP_BACKEND_URL="https://4567-$GITPOD_WORKSPACE_ID.$GITPOD_WORKSPACE_CLUSTER_HOST" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="us-east-1_N7WWGl3KC" \
--build-arg REACT_APP_CLIENT_ID="575n8ecqc551iscnosab6e0un3" \
-t frontend-react-js \
-f "$FRONTEND_REACT_JS_PATH/Dockerfile.prod" \
"$FRONTEND_REACT_JS_PATH/."
```

We test the file and it builds. While waiting on this to build, we do the same to `backend-flask.prod`

```sh
#! /usr/bin/bash 

ABS_PATH=$(readlink -f "$0")
BUILD_PATH=$(dirname $ABS_PATH)
DOCKER_PATH=$(dirname $BUILD_PATH)
BIN_PATH=$(dirname $DOCKER_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"

docker build \
-f "$BACKEND_FLASK_PATH/Dockerfile.prod" \
-t backend-flask-prod \
"$BACKEND_FLASK_PATH/."
```

The next file we update pathing for is `./bin/ddb/seed`

```python
current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
from lib.db import db
```

Then `./bin/db/schema-load`

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
BIN_PATH=$(dirname $ABS_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"
schema_path="$BACKEND_FLASK_PATH/db/schema.sql"
echo $schema_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $schema_path
```

Moving onto `./bin/db/seed`

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-seed"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
BIN_PATH=$(dirname $ABS_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"
seed_path="$BACKEND_FLASK_PATH/db/seed.sql"
echo $seed_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $seed_path
```

`./bin/db/setup`

```sh
#! /usr/bin/bash
set -e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-setup"
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
DB_PATH=$(dirname $ABS_PATH)

source "$DB_PATH/drop"
source "$DB_PATH/create"
source "$DB_PATH/schema-load"
source "$DB_PATH/seed"
python "$DB_PATH/update_cognito_user_ids"

```

`./bin/db/update_cognito_user_ids`

```python
current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
from lib.db import db
```

We then updated the path for Postgres in our `.gitpod.yml` file:

```yml
    command: |
      export GITPOD_IP=$(curl ifconfig.me)
      source  "$THEIA_WORKSPACE_ROOT/bin/rds/update-sg-rule"   
```

At this point, the Dockerfile we were building has completed. We now need to push and tag it. We already created a script to do this for our `backend-flask-prod`, now we need to create one for our frontend, so we create `frontend-react-js.prod` in the `./bin/docker/push` directory.

```sh
#! /usr/bin/bash

ECR_FRONTEND_REACT_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/frontend-react-js"
echo $ECR_FRONTEND_REACT_URL

docker tag frontend-react-js:latest $ECR_FRONTEND_REACT_URL:latest
docker push $ECR_FRONTEND_REACT_URL:latest
```

After making the file executable with a chmod, we run the file to tag and push our frontend build. We decide to create a new `force-deploy` file for the frontend as well, since we already have one for the backend. In the `./bin/ecs` directory, we create `force-deploy-frontend-react-js`.

```sh
#! /usr/bin/bash

CLUSTER_NAME="cruddur"
SERVICE_NAME="frontend-react-js"
TASK_DEFINITION_FAMILY="frontend-react-js"

LATEST_TASK_DEFINITION_ARN=$(aws ecs describe-task-definition \
--task-definition $TASK_DEFINITION_FAMILY \
--query 'taskDefinition.taskDefinitionArn' \
--output text)

echo "TASK DEF ARN:"
echo $LATEST_TASK_DEFINITION_ARN

aws ecs update-service \
--cluster $CLUSTER_NAME \
--service $SERVICE_NAME \
--task-definition $LATEST_TASK_DEFINITION_ARN \
--force-new-deployment
```

We make this file executable with a chmod, then run the file. This forces a new deployment of the frontend image. We test our production backend by navigating to our custom domain, adding the additional subdomain and path: `https://api.thejoshdev.com/api/health-check` - this returns true. Next we introduce an error in the URL purposely, to make sure our debug menu doesn't appear - this returns an "Internal Server Error" so our debugging menu is not present. 

Andrew begins to take us down the path to make sure that we're using Python in a safe way. We begin researching Flask debugging. Andrew begins telling us about Ruby Rack, and looks up the Python equivalent, which turns out to be WSGI. The built-in debugger for Flask is Werkzeug, which is a utility library for WSGI. We begin searching to see if we can run this in production mode. According to their documentation, it's intended only during local development. 

![image](https://user-images.githubusercontent.com/119984652/233843793-79e4b39a-566d-4abb-b5de-9612bef66fc8.png)

Andrew further clarified, asking ChatGPT why you can't use Werkzeug in production mode:

![image](https://user-images.githubusercontent.com/119984652/233844078-9424d255-fc61-496b-8ccd-c5ea4cba7701.png)

Andrew then discussed several different options for debugging including possibly Gunicorn, but said we'll have to see how things go moving forward. 

Moving on, Andrew mentions that DynamoDB isn't working in production mode, so we are going to debug that. We go back to our production app, through the web browser. We're logged in, but there's no data.

![image](https://user-images.githubusercontent.com/119984652/234130909-11d4c24c-5621-49bd-a956-daa651b92b10.png)

After inspecting the page, we find that its doing a GET from the wrong location. Andrew suspects this is from pushing the image earlier. We go back to our `./bin/docker/build/frontend-react-js-prod` file and review our code.

We update this:

```sh
docker build \
--build-arg REACT_APP_BACKEND_URL="https://4567-$GITPOD_WORKSPACE_ID.$GITPOD_WORKSPACE_CLUSTER_HOST" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="us-east-1_9999999999" \
--build-arg REACT_APP_CLIENT_ID="99999999999999999999" \
-t frontend-react-js \
-f "$FRONTEND_REACT_JS_PATH/Dockerfile.prod" \
"$FRONTEND_REACT_JS_PATH/."
```

To this:

```sh
docker build \
--build-arg REACT_APP_BACKEND_URL="https://api.thejoshdev.com" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="us-east-1_9999999999" \
--build-arg REACT_APP_CLIENT_ID="99999999999999999999" \
-t frontend-react-js \
-f "$FRONTEND_REACT_JS_PATH/Dockerfile.prod" \
"$FRONTEND_REACT_JS_PATH/."
```

Our environment variable for REACT_APP_BACKEND_URL was incorrect. We rebuild. 

```sh
./bin/docker/build/frontend-react-js-prod
```

After it builds, we push and tag it again as well: 

```sh
./bin/docker/push/frontend-react-js=prod
```

We then deploy it. 

```sh
./bin/ecs/force-deploy-frontend-react-js
```

We go back into ECS to check the status of the new deployment. After several moments, the deployment still hasn't shown as healthy yet, so we move over to EC2 and check the target groups. The old target group is still draining. This leads us to Andrew telling us about types of deployments and that when we deploy, we're doing an ECS deployment, which is according to AWS, "replacing the current running version of the container with the latest version. The number of containers ECS adds or removes from the service during a rolling update is controlled by adjusting the minimum and maxiumum number of healthy tasks allowed during a service dployment, as sepcified in the DeploymentConfiguration."

After waiting a bit longer for the target group to drain, we decide to go ahead and navigate to our production app anyways. The page loads through Inspect in the browser with no errors this time. Through this process, Andrew decides finding the correct scripts to run from what directory is becoming quite combersome due to the amount of scripts that we have. To alleviate the difficulty with this, from with our `/bin/` directory, we create two folders: `frontend` and `backend`. We begin moving and renaming our various scripts, moving those related to `frontend-react-js` going to the frontend, those related to `backend-flask` to our backend folder. In our build scripts for the both the frontend and the backend, we had to update the pathing, as it has changed.

```sh
#for the backend

ABS_PATH=$(readlink -f "$0")
BACKEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $BACKEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"

#for the frontend

ABS_PATH=$(readlink -f "$0")
FRONTEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $FRONTEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
FRONTEND_REACT_JS_PATH="$PROJECT_PATH/frontend-react-js"
```

We reload our production app at this point and we now have data! Now that we have fixed that issue, we move onto the Messages section. Messages are not populating, and Andrew suspects this is due to our local users not existing in the production database. We need to seed some users. We connect to the remote database through the Terminal.

```sh
./bin/db/connect prod
```

After connecting to the database, we run a `SELECT * FROM users;` which returns our Cognito account that we created previously. We need to populate some users so we have something to work with. For reference, we pull up `./backend-flask/db/seed.sql` and copy the command into the terminal connected to our Postgres database. 

```sql
INSERT INTO public.users (display_name, email, handle, cognito_user_id) VALUES ('Andrew Bayko','bayko@exampro.co' , 'bayko' ,'MOCK') 
```

Andrew accidentally copies the line with his user information again instead for the manual insert above, so when he tests the `/messages/new/bayko` page of his web app, his Inspect page comes back with a 500 error returned on the GET for `short`. 

![image](https://user-images.githubusercontent.com/119984652/234137388-0d6ab4fa-7476-4bc1-a8a5-03c69b4831df.png)

That leads us to go check out our Rollbar account to see if we have any error tracking. 

![image](https://user-images.githubusercontent.com/119984652/234137908-c894a817-7d48-44ba-8a84-ab3ca9a341e0.png)

Andrew shows us where the `short` that was returning the 500 error is coming from. We navigate to `/backend-flask/services/users_short.py` 

![image](https://user-images.githubusercontent.com/119984652/234138767-b4c9688d-63d5-409f-8023-b5e1d423ce7a.png)

We go back to Rollbar, check Cloudwatch logs, view RDS; none of these are showing us what the problem was. Eventually, from the terminal, we run a query: 

```sql
SELECT * FROM users;
```

At this point, Andrew sees that he's added himself twice to the database, but it raises the question. If our app did not find `/messages/new/bayko`why wasn't there an error other than a 500 error? We navigate to our `./backend-flask/lib/db.py` file and pull up our code:

```python
    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        if json == None:
          "{}"
          else:
            return json[0]
```

We want to see what's returning, so we docker compose up our local environment. We need to seed data again, so we use this opportunity to run another script `./bin/db/setup`. The script won't run however, because the pathing is now incorrect since we restructured our `/bin/` folder. While working through the pathing, we're repeatedly running `./bin/db/setup`, but it's failing because there's sessions connected to the database that we're attempting to drop through part of the script. Eventually after composing our environment up and down several times with the same issue when trying to drop the database, we close out of our workspace, and start up a new one through Gitpod. We again run our `./bin/db/setup` file, this time it errors on an issue with pathing in the `./bin/db/seed` file. With the pathing fixed, we again try the `setup` file, but it again tells us the database is being accessed by other users when we attempt to drop the table. We quickly search for and find sufficient code to kill sessions to a Postgres database, then in our `./backend-flask/db` directory, we create `kill-all-connections.sql`.

```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE   
-- don't kill my own connection!
pid <> pg_backend_pid()
-- don't kill the connections to other databases
AND datname = 'cruddur';    
```

Then, in `./bin/db` we create `kill-all`.

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-kill-all"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
DB_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $DB_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"
kill_path="$BACKEND_FLASK_PATH/db/kill-all-connections.sql"
echo $kill_path

psql $CONNECTION_URL cruddur < $kill_path
```

We test the script.

```sh
./bin/db/kill-all
```

It completes. We attempt to drop the database again.

```sh
./bin/db/drop
```

The database drops successfully this time. We again run our `setup` file.

![image](https://user-images.githubusercontent.com/119984652/234407954-aaccc81b-a38a-4ed9-8b3b-98685efa0c2c.png)

We view the pathing in our `update_cognito_user_ids` file. We needed to add 'backend-flask' to the path.

```py
current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
from lib.db import db
```

We continue on, loading our Message data. 

```sh
./bin/ddb/schema-load
```

We attempt to seed the data running `./bin/ddb/seed` but we obtain a `ModuleNotFoundError: No module named 'lib'` error. We open `./bin/db/seed` and view the pathing. It needed updated as well, just the same as above. We make the same pathing change as above, then try running the `seed` file again. This time, it seeds our data. 

With our local environment completely running now, we open the backend port in a browser, then check the path: `/api/users/@bayko/short` 

![image](https://user-images.githubusercontent.com/119984652/234410238-4b55ac3b-6620-448a-804e-fc98942ed456.png)

We open the frontend port instead, then sign into our web app. We see that we are not returning any data. A quick refresh of the browser, and data returns. We now navigate to the path `/messages/new/bayko` and Inspect the page. 

![image](https://user-images.githubusercontent.com/119984652/234410975-d1f73386-b2ec-47b4-81d7-81708ffba491.png)

It's returning what its supposed to now. We alter the path to a user that does not exist in our database. `/messages/new/asdfasdf`. The short now returns a 500 error. 

![image](https://user-images.githubusercontent.com/119984652/234411509-35c35f1b-79d7-4b5f-b289-0028dc541e83.png)

We check the `backend-flask` logs through our terminal:

![image](https://user-images.githubusercontent.com/119984652/234411693-3919d68c-c94f-494a-a6f1-ae414c254978.png)

The data returning is not what is expected. We open our `users_short.py` and our `backend-flask/lib/db.py` files. Andrew explains that he had thought `json` would return None, but it's returning something. So we begin debugging by printing a few lines.

![image](https://user-images.githubusercontent.com/119984652/234413246-cf0adbdb-4ef6-4b78-8306-d3e66a75fd59.png)

Immediately Andrew recongnizes what the problem is. We needed to add a return.

```python
    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        if json == None:
          return "{}"
          else:
            return json[0]
```

With the return added, we refresh the web app, then inspect the page again.

![image](https://user-images.githubusercontent.com/119984652/234413665-07321728-df15-4f52-88f5-bdb3d029d144.png)

It's returning what it's supposed to return now. We're ready to push the changes to production, so we run our build script for our backend. 

```sh
./bin/backend/build
```

![image](https://user-images.githubusercontent.com/119984652/234414336-de65abdd-b725-43a0-9ee9-41d5aff0b23d.png)

We need to update the pathing in our `build` script. 

```sh
ABS_PATH=$(readlink -f "$0")
BACKEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $BACKEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"
```

We go ahead and fix the pathing in our `./bin/frontend/build` script as well:

```sh
ABS_PATH=$(readlink -f "$0")
FRONTEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $FRONTEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
FRONTEND_REACT_JS_PATH="$PROJECT_PATH/frontend-react-js"
```

We run the `build` script for the backend again, this time it works. We tag and push the image again as well. 

```sh
./bin/backend/push

./bin/backend/deploy
```

We connect to our production database through the terminal.

```sh
./bin/db/connect prod
```

From the terminal, we manually insert a user into the database:

```SQL
INSERT INTO public.users (display_name, email, handle, cognito_user_id) VALUES ('Andrew Bayko', 'bayko@exampro.co' , 'bayko' ,'MOCK');
```

From our production web app, we go again to `/messages/new/bayko`, then inspect the page. We return all 200 statuses.  When we test the app to send a message, it works!

![image](https://user-images.githubusercontent.com/119984652/234416272-fb813ad6-6dd8-4989-9154-4055dc779a99.png)

We now direct our attention towards an issue we've been having with our Cognito token. Our `frontend-react-js/src/lib/CheckAuth.js` file declares a const for checkAuth that we thought would attempt to renew our Cognito token. It has not been doing so. Andrew explains we're going to have to wrap this in another function to make sure this gets set. We research token refresh for AWS Cognito using Amplify, noting a possible solution using `Auth.currentSession`, then go back to our code for `CheckAuth.js`

```js
const checkAuth = async (setUser) => {
  Auth.currentAuthenticatedUser({
    // Optional, By default is false.
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false
  })
  .then((user) => {
    console.log('user',user);
    return Auth.currentAuthenticatedUser()
  }).then((cognito_user) => {
      console.log('cognito_user',cognito_user);
      setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
```

It looks like `Auth.currentAuthenticatedUser` is getting called twice and Andrew's not sure why that was, so we logged out the data. Then we reloaded the page and inspected it. 

![image](https://user-images.githubusercontent.com/119984652/234421141-1ea7d683-0594-4d2a-913e-27da3f72d583.png)

The same information is being returned twice. Looks like we will be using `Auth.currentSession`. We update our code.

```js
const checkAuth = async (setUser) => {
  Auth.currentAuthenticatedUser({
    // Optional, By default is false.
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false
  })
  .then((cognito_user) => {
    console.log('cognito_user',cognito_user);
    setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
    return Auth.currentSession()
  }).then((cognito_user) => {
      console.log('cognito_user_session',cognito_user_session);
      localStorage.setItem("access_token", cognito_user_session.accessToken.jwtToken)
  })
  .catch((err) => console.log(err));
  
```

Andrew explains that we're going to have to do this check every time we do API calls as well, so we will likely need to wrap this around other functions. From `CheckAuth.js` we create a new function, making a call to the `Auth.currentSession`. 

```js
const getAccessToken = async () => {
  Auth.currentSession()
  .then((cognito_user_session) => {
    localStorage.setItem("access_token", cognito_user_session.accessToken.jwtToken);
    return localStorage.getItem("access_token")
    
  })   
  .catch((err) => console.log(err));
}
```

From our `HomeFeedPage.js` we adjust our API call to pass along `getAccesstoken`. We also import from `CheckAuth.js` 

```js
import {checkAuth, getAccessToken} from 'lib/CheckAuth';

  const loadData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/home`
      const access_token = getAccessToken()
      console.log('access_token',access_token)
      const res = await fetch(backend_url, {
        headers: {
          Authorization: `Bearer ${access_token}`
        },
        method: "GET"
      });
```

We test our local web app. 

![image](https://user-images.githubusercontent.com/119984652/234427066-d1e1058d-dba3-4517-8c2b-28bb6c7c7149.png)

This could be due to the updated code, so we find and replace all instances of `import CheckAuth` with `import {checkAuth}`. Then we refresh the page. This makes no change. As it turns out, we need to export our functions from `CheckAuth.js`.

```js
export async function getAccessToken(){
  Auth.currentSession()
  .then((cognito_user_session) => {
    localStorage.setItem("access_token", cognito_user_session.accessToken.jwtToken);
    return localStorage.getItem("access_token")
    
  })   
  .catch((err) => console.log(err));
}

export async function checkAuth(setUser){
  Auth.currentAuthenticatedUser({
    // Optional, By default is false.
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false
  })
  .then((cognito_user) => {
    console.log('cognito_user',cognito_user);
    setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
    return Auth.currentSession()
  }).then((cognito_user) => {
      console.log('cognito_user_session',cognito_user_session);
      localStorage.setItem("access_token", cognito_user_session.accessToken.jwtToken)
  })
  .catch((err) => console.log(err));

  
```

We reload the web app again, and it is again displaying correctly. However, one of our console.logs are coming back with `access_token` undefined. We again review our code both for the API call in `HomeFeedPage.js` and the getAccessToken function in `CheckAuth.js`

```js
export async function getAccessToken(){
  Auth.currentSession()
  .then((cognito_user_session) => {
    const access_token = cognito_user_session.accessToken.jwtToken
    console.log('11',access_token)
    localStorage.setItem("access_token", access_token)
  })   
  .catch((err) => console.log(err));
}
```

Note that we console.log the same information in both files. 


```js
  const loadData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/home`
      await getAccessToken()
      const access_token = localStorage.getItem("access_token")
      console.log('22',access_token)
      const res = await fetch(backend_url, {
        headers: {
          Authorization: `Bearer ${access_token}`
        },
        method: "GET"
      });
```

We again refresh the page and inspect it. It's identical information.

![image](https://user-images.githubusercontent.com/119984652/234430724-0e86cd15-bb19-474e-a693-f49d70c4ed80.png)

We do a find and replace on every file in our workspace that contains `Authorization`, then add a line to import our new functions.

```js
import {checkAuth, getAccessToken} from '../lib/CheckAuth';
```

Then, wherever `Authorization` appears, in these cases passing our Authorization headers for CORS, we're also adding two lines of code above it:

```js
await getAccessToken()
const access_token = localStorage.getItem("access_token")
```

We refresh our web app, then click through the various pages. Of the pages currently connected correctly, our token stays logged in now. When we inspect, we get back nothing but 200 status codes, so we're in good shape. 

