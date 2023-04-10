# Week 6 and 7  — Deploying Containers

We started these 2 weeks with the revelation that we're not going to be able to use ECS EC2, and instead will use Fargate. Andrew explained initially we were going to use ECS EC2 to stay away from spend for the bootcamp, but to stay within the free tier of EC2, it would require too much complexity and the spend incurred with Fargate is minimal. 

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

