# Week 9 — CI/CD with CodePipeline, CodeBuild and CodeDeploy

This week we opened the livestream with Andrew introducing Du'An Lightfoot, a Senior Cloud Networking Dev Advocate of AWS. He's going to assist us with implementing CI/CD. We spin up a new workspace, then do a Docker compose up to start our environment. We run our various scripts to get data to our web app, then launch it. From there, we sign in. Andrew explains our current setup. If we make changes to our production web application code, if we want to roll out the changes we have to build the images manually, we have to push them to AWS ECR, and then we have to trigger a deploy. We are looking to automate this process. To do this, we will use AWS CodePipeline. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/bac07790-9be9-4f33-b4b3-01d2c13bba23)

We create a new pipeline. Andrew explains there's going to be a lot of backtracking during this, just getting things all setup. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/1aaaadd9-ef89-46b5-bccd-e9facae5b7eb)

We name the Pipeline `cruddur-backend-fargate`. We're going to create a new service role for this pipeline. We allow a default S3 bucket to be created for our Artifact Store, using a Default AWS Managed Key for Encryption. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/989719c6-30d9-406c-944b-0831aa693116)

We click Next and now we get to add a source stage. We select Github (Version 2). We create a new connection, named `cruddur`. Then we click Connect to GitHub. We select Install a new App, which we're then redirected to sign in through our GitHub account and install the AWS Connector for GitHub.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/35f9771f-6db2-4ac7-8a6b-d87ce3936560)

We're then prompted to select which Repositories from GitHub we would like to allow access. We select our `aws-bootcamp-cruddur-2023` repository. We hit Connect, and our GitHub connection is ready for use. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/1a02cad3-3946-4db8-8ae3-3015503ee76d)

Next, we add our `aws-bootcamp-cruddur-2023` repository that we gave access to in the previous step and take a pause here. Andrew directs us over to GitHub, as he wants us to create a new branch from our repository. We create a new branch named `prod`. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/7e2e4820-f917-46e9-9afa-88f1ffd1e7c5)

We can now move back over to CodePipeline and continue on. We select a branch name and make it the `prod` branch we just created. Then, under "Change detection options", we select "Start the pipeline on source code change". This will automatically start the pipeline when a change is detected in our repository. Then for our Output artifact format, we leave the CodePipeline default and click Next.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/794a147f-759c-443e-9204-346126308d62)

On the next page, we skip the build stage, as we're wanting to do this later. We're immediately prompted that we cannot skip the deploy stage. AWS notes "Pipelines must have at least two stages. Your second stage must be either a build or deployment stage. Choose a provider for either the build stage or deployment stage." We chose a deploy provider of Amazon ECS. We select our region, then choose our existing cluster, `cruddur`. For service name, we use `backend-flask` service from ECS. We leave the Image definition file blank for now, and click Next. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/00a50955-a4ef-4291-b200-d0cf0d5c9d73)

We review our steps, then click Create Pipeline.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/b7d0031f-0de4-434e-9b6f-d1b0b8c91ac3)

The pipeline is successfully created. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/f11e03e3-2dba-47c1-8808-9196193dfbd5)

However, the Deploy fails, because we have not configured it yet.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/1db82b69-dfcd-42ab-b2ad-278ecca92641)

Andrew reviews the error onscreen.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/ab5d7b9a-62b9-45c6-a4a1-07a0fc6f0bad)

The Deploy is expecting a file named `imagedefinitions.json`. We will need to make sure it's placed in our pipeline's S3 artifact bucket. Andrew then says we will need to add a build step to build out our image. We select Edit, then Add stage between Source and Deploy. We name the stage, `bake-image`. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/c6155d22-d248-4d3e-b81a-7560b5b6074e)

We add an action group to `bake-image`. We name the Action `build`, the Action provider AWS CodeBuild. We select our region, then select SourceArtifact as our Input artifacts. In the next step, we need to provide a Project name, but we don't have a Build project created yet. This is what Andrew was meaning when he said there'd be some backtracking to set things up while we continue. Instead of select Create Project and using the tiny window AWS provides, we open a new AWS console tab, then go to CodeBuild. From there, we create a Build Project. We name the project `cruddur-backend-flask-bake-image` and enable the build badge.  

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/b3067df5-635e-4852-bc6c-45d6ad054b05)

We select our source provider as GitHub, then again walk through the steps to connect our repository from GitHub. After it's connected, we select our `aws-bootcamp-cruddur-2023` repository. Under Source version, we enter the name of the branch we want to use, `prod`. We leave the additional configuration alone, scrolling down to the Primary source webhook events. We check the box for "Rebuild every time a code change is pushed to this repository", using Single build as the Build Type. 

Under Event type, we add `PUSH` and `PULL_REQUEST_MERGED` as our events to trigger a new build. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/ba3095e1-23f3-410e-a3b0-24d17f12018c)

Under Environment, we selected Managed Image, using Amazon Linux 2 as the operating system. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/edc4ec95-d7b9-456e-8fd4-72ace1cf3a9e)

We select a Standard runtime, the latest image, Linux environment type. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/35c48514-1163-4636-b423-b8fb9851b902)

We check the box for Privileged because we want to build Docker images. We're going to also create a new service role named `codebuild-cruddur-service-role`.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/93f8fa2f-002a-44e5-904e-bf3b3cde9ab3)

We adjust the timeout of the build to 20 minutes, as we don't want to wait too long if the build fails. We don't use a certificate, then we select our default VPC, subnets, and security group for now. Moving onto Computer, we leave it on the default option of 3 GB memory, 2 vCPUs. Back in our workspace, we create a new file in the root of `./backend-flask` named `buildspec.yml`. 

```yml
# Buildspec runs in the build stage of your pipeline.
version: 0.2
phases:
  install:
    runtime-versions:
      docker: 20
    commands:
      - echo "cd into $CODEBUILD_SRC_DIR/backend"
      - cd $CODEBUILD_SRC_DIR/backend-flask
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $IMAGE_URL
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...          
      - docker build -t backend-flask .
      - "docker tag $REPO_NAME $IMAGE_URL/$REPO_NAME"
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image..
      - docker push $IMAGE_URL/$REPO_NAME
      - echo "imagedefinitions.json > [{\"name\":\"$CONTAINER_NAME\",\"imageUri\":\"$IMAGE_URL/$REPO_NAME\"}]" > imagedefinitions.json
      - printf "[{\"name\":\"$CONTAINER_NAME\",\"imageUri\":\"$IMAGE_URL/$REPO_NAME\"}]" > imagedefinitions.json

env:
  variables:
    AWS_ACCOUNT_ID: 999999999999
    CONTAINER_NAME: backend-flask
    IMAGE_URL: 9999999999.dkr.ecr.us-east-1.amazonaws.com
    REPO_NAME: backend-flask:latest
artifacts:
  files:
    - imagedefinitions.json
```

We move back over to CodeBuild in AWS. We know we're needing to pass environment variables, so we open a new tab and go to ECS to view our `backend-flask` service and see what env vars are being passed there.  We pass these variables in our `buildspec.yml` file initially.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/53caffeb-6eaf-4d85-8845-01dc2d64264e)

Moving on with CodeBuild, we can specify our Buildspec file. We select to use a buildspec file, then give the path to the file, which is `backend-flask/buildspec.yml`. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/887f73c1-5be6-4977-9439-08163d517f6c)

Scrolling further down, we enable logs from CloudWatch, then give a Group name and stream name. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/bff1c74f-ddfc-4ef8-811d-fab785e8a791)

Then we create the build project. The project is now created. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/69459767-e3ad-408b-ad63-8bee23903a75)

Our project doesn't build automatically. Instead, we go back over to GitHub and initiate a Pull request.  We merge our `main` branch into `prod`. We create the Pull request, then merge the Pull request. Back over in CodeBuild, our build has triggered multiple times now, not just from the Pull request. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/6f7938e6-2789-44ec-860c-4a9bfca87ea7)

We go back through and edit the source, removing the `PUSH` event type, leaving us with only `PULL_REQUEST_MERGED` to trigger our build. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/416de2a3-652b-4726-9859-253025eebe06)

We stop all the builds in CodeBuild, then start a new one. The build never completes. We stop the build. We edit the environment of the build, removing the VPC option, subnet option, and security group option we set previously. We also realize that we aren't passing anything to our `./bin/backend/build` script when building the backend, so we will not need to pass our env vars to our `buildspec.yml` file either. We remove these. 

I again reattempt the build. When I view the logs, I'm getting an `AccessDeniedException` error. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/20a7a689-d929-4826-a378-fa67e6ba7760)

I'm able to resolve this by creating an inline policy in IAM for the `codebuild-cruddur-service-role` created earlier. 

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "ssm:GetParameters",
            "Resource": [
                "arn:aws:ssm:us-east-1:999999999999:parameter/backend-flask/*",
                "arn:aws:ssm:us-east-1:999999999999:parameter/cruddur/backend-flask/*",
                "arn:aws:ssm:us-east-1:999999999999:parameter/*"
            ]
        }
    ]
}
```

With that, I attempt the build again, this time triggered by another pull request. The build succeeds.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/bebcf3c5-d506-4dba-81c1-e642b05e900b)

We move back over to CodePipeline and edit the pipeline. We add an additional stage between the Source and the Deploy named `build`.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/8235bf45-0605-45d3-9ffb-a91c82aafbc7)

On the action, we name it `bake`, the Action provider AWS CodeBuild, then select our region. We again select SourceArtifact as our Input Artifacts, then select our CodeBuild project for the Project name.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/a7578820-e11c-42c0-9273-30135298fe9f)

We then finish creating the action. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/02cbb59b-66e7-482d-9db0-e028fdd39c44)

We save the changes to our pipeline, then release the changes. Our build fails on the Deploy.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/ac3a035f-ee1b-4229-b399-66a0a4452cc9)

Andrew displays the error:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/420c4544-eece-44db-b064-2f2ef90468d3)

We edit the `build` stage of the pipeline, adding an Output artifact name of `ImageDefinition`. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/2300a3b2-8215-48bb-b85e-78ecf3ecb3aa)

Then, we edit the Deploy action, changing the Input Artifacts to the `ImageDefinition` artifact outputted in the previous stage.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/4bc6e0ba-e3b7-49c4-9352-24a1bcaebd0d)

We save the pipeline, then release the changes. Our pipeline is now failing at the build stage.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/05cae377-2c1a-4a10-9405-5fc78cfdb16d)

There's a `CLIENT_ERROR` message in the logs stating there's no matching artifact paths. With this, Andrew knows what's wrong and guides us back to our workspace. In our `buildspec.yml` file, we cd to our base path in the `post_build`. 

```yml
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image..
      - docker push $IMAGE_URL/$REPO_NAME
      - cd $CODEBUILD_SRC_DIR
      - echo "imagedefinitions.json > [{\"name\":\"$CONTAINER_NAME\",\"imageUri\":\"$IMAGE_URL/$REPO_NAME\"}]" > imagedefinitions.json
      - printf "[{\"name\":\"$CONTAINER_NAME\",\"imageUri\":\"$IMAGE_URL/$REPO_NAME\"}]" > imagedefinitions.json
```

We commit this change to our code, then submit another pull request. We're merging `main` into `prod`. Then we merge the request. The Deploy succeeds this time. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/dad63eb4-da1a-4eba-bcf4-6a67d98fe35b)

We want to make sure this is working so we need to submit a change to our code. We open `./backend-flask/app.py` and add a change to our health check returned data. 

```py
@app.route('/api/health-check')
def health_check():
  return {'success': True, 'ver': 1}, 200
```

We commit the change, then create another pull request. We head back over to CodePipeline. Once our pipeline passes the build stage, we open EC2 > Load Balancing > Target Groups and update the target groups for our `backend-flask`. One target must completely drain before the new target is active, the service is running, and the deploy stage completes.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/48785901-d417-4bea-a41f-8e68585d4870)

We test our API health check to see if we're up to date. We are. The health check is displaying our updated code.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/55b1b835-2283-4994-9cbe-687f9fa68f86)

We check our pipeline again, and the deploy stage has completed. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/64c5597e-9f34-4ab5-a4c8-a40bac4ba57c)

That completed Week 9. 
