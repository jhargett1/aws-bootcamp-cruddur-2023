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

