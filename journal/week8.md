# Week 8 — Serverless Image Processing

We started off this week with Andrew introducing Kristi Perreault, an AWS serverless hero. Kristi is going to be leading instruction during the livestream. Kristi introduced herself and let us know she's a Principal Software Engineer at Liberty Mutual Insurance, focusing on serverless enablement and development for the last several years. She said Liberty Mutual has gone all in on the AWS CDK space, which led her to introducing us into AWS CDK. 

CDK, or Cloud Development Kit, is an IaaC tool. Where in CloudFormation you would define your infrastructure in .json or .yml, in CDK you could define your infrastructure in TypeScript, JavaScript, Python, Java, C#/. Net, or Go. Kristi mentioned there's a couple different versions of CDK, we will be using version 2. If we've never used CDK before, that's fine, you don't need to know about version 1, there were import and packaging changes. Version 2 is easier to use. 

Kristi showed us the AWS CDK reference docs for API, focusing on Constructs. The AWS Construct library represents all the resources available on AWS. There's 3 levels of constructs in this library, but Kristi says we're going to be focusing on the level 1 constructs, at least during the livestream. AWS refers to these as CFN Resources, or low-level constructs. They represent all resources available in AWS CloudFormation. Each level higher gets a little more complex. 

We get started with a visual representation of what we will be doing. 

![image](https://user-images.githubusercontent.com/119984652/235264536-77d2afec-4cda-453c-881e-a06046e5ea99.png)

Kristi mentions that we will be creating resources for an S3 bucket, a Lambda function that will process our image, interactions with an API, and a webhook. 

In our workspace, we create a new directory named `thumbing-serverless-cdk` through the CLI. We then `CD` into the directory.

```sh
mkdir thumbing-serverless-cdk

cd thumbing-serverless-cdk
```

So our packages are recognized, we must install `aws-cdk` in our directory.

```sh
npm install aws-cdk -g
```

The `-g` means globally, which will allow CDK to be referenced wherever we are in our directories. From the CLI, we initialize a CDK application running Typescript. Kristi mentioned you can use one of the other languages supported by CDK that you're more familiar with here as well.

```sh
cdk init app --language typescript
```
 
 ![image](https://user-images.githubusercontent.com/119984652/235265884-64150b47-73f3-4c2a-a76f-4d59b478c3ca.png)
 
 Kristi explains what CDK is doing from our terminal initialization. She said it's giving us a blank project for CDK development with TypeScript which includes all of the typical files you'd have on a project:
 
 ![image](https://user-images.githubusercontent.com/119984652/235266184-052e7530-b8ef-40ab-8de7-061bba83809f.png)

The `package.json` and the `package-lock.json` file are what house our dependencies. Here, we look at our `package.json` file:

```json
{
  "name": "thumbing-serverless-cdk",
  "version": "0.1.0",
  "bin": {
    "thumbing-serverless-cdk": "bin/thumbing-serverless-cdk.js"
  },
  "scripts": {
    "build": "tsc",
    "watch": "tsc -w",
    "test": "jest",
    "cdk": "cdk"
  },
  "devDependencies": {
    "@types/jest": "^29.4.0",
    "@types/node": "18.14.6",
    "aws-cdk": "2.73.0",
    "jest": "^29.5.0",
    "ts-jest": "^29.0.5",
    "ts-node": "^10.9.1",
    "typescript": "~4.9.5"
  },
  "dependencies": {
    "aws-cdk-lib": "2.73.0",
    "constructs": "^10.0.0",
    "dotenv": "^16.0.3",
    "sharp": "^0.32.0",
    "source-map-support": "^0.5.21"
  }
}
```

By default, we're given the latest version of `aws-cdk` out of the box. Kristi said that these are updated relatively quickly and frequently. Moving further into the new directory, we expand the `lib` folder and this houses our `thumbing-serverless-cdk-stack.ts` file. Kristi explains this is where we will define all of our infrastructure. CDK prefills the file with a sample resource so you as an engineer can see how it works.

![image](https://user-images.githubusercontent.com/119984652/235266883-e393833f-19eb-4490-a6fc-f9413ecc857c.png)

We begin importing `s3` for our S3 bucket we're going to need. 

```ts
import * as s3 from 'aws-cdk-lib/aws-s3';
```

We need to define our bucket with a bucket name. 

```ts
const bucketName: string = process.env.THUMBING_BUCKET_NAME as string;
```

We create a new function named `createBucket`. When we create a bucket, we're taking in our `bucketName` as a string.

```ts
createBucket(bucketName: string){
  const bucket = new s3.Bucket(this, 'ThumbingBucket');
}
```

Kristi explains we set our scope. `this` is literally this construct we are building. The `id` we're setting is `'ThumbingBucket'`. Kristi notes we want to give the function a few more properties or `props` to make sure that it interacts with our other objects and has a name for us to identify it. We do this with `{}` brackets. One of the properties we add is a `removalPolicy`, which is an IAM policy. 

```ts
createBucket(bucketName: string): s3.IBucket {
  const bucket = new s3.Bucket(this, 'ThumbingBucket', {
    bucketName: bucketName,
    removalPolicy: cdk.RemovalPolicy.DESTROY
    });
    return bucket;
}
```

Also since this is `TypeScript` we have to explicitly state what is being returned. We're returning the `bucket` but on the first line above, we're returning it as an `s3.IBucket`. 

Per ChatGPT for added detail: 
"  In TypeScript, s3.IBucket is an interface that defines the shape of an S3 bucket object, but does not provide the implementation details. The `s3.Bucket` object is returned, which satisfies the `s3.IBucket` interface, since `s3.Bucket` implements the `IBucket` interface. This returned object can then be used to interact with the S3 bucket, using the methods and properties provided by the `s3.Bucket` class."

Back in our definition, we want to call this and make a bucket from our main class. We define another constant.

```ts
// Previously added
const bucketName: string = process.env.THUMBING_BUCKET_NAME as string;

// New bucket we just added
const bucket = this.createBucket(bucketName);
```

Kristi now wants to show us the power of `cdk synth` from the terminal. The `cdk synth` command generates a CloudFormation template from your CDK code, allowing you to see the complete AWS infrastructure that will be created or modified by your CDK app. This template can be used to inspect the resources, review the dependencies between resources, and even manually create or modify the stack outside of the CDK, if needed.

```sh
cdk synth
```

![image](https://user-images.githubusercontent.com/119984652/235302048-02658cbf-1714-4b96-9e47-572a6166c3b4.png)

Although the template is output in our terminal as `.yml`, within our `thumbing-serverless-cdk` directory we created, there's a new folder named `cdk.out`. Within that folder, if we access the `ThumbingServerlessCdkStack.template.json` file, it displays our CloudFormation template in `.json`.

![image](https://user-images.githubusercontent.com/119984652/235302887-2fb75b37-52f9-4bee-bd42-e6867d6ba45d.png)

![image](https://user-images.githubusercontent.com/119984652/235302903-f9aca84f-6290-4c9f-9e01-7ef8daf02c08.png)

Kristi mentioned this is a good way to recognize errors with the infrastructure if you're already familiar with CloudFormation templates. The entire `cdk.out` folder acts similarly to a `.gitignore` file or `node_modules` folder however. It will not be committed with our code. 

Moving on, we must bootstrap our account. Kristi pulls up the documentation and explains bootstrapping is the process of provisioning resources for the AWS CDK before you can deploy AWS CDK apps into an AWS environment, which is our AWS account and region.  We only have to bootstrap once per AWS account, or per region, if you're wanting multiple regions. Moving to our terminal, we perform a bootstrap.

```sh
cdk bootstrap "aws://<AWSACCOUNTNUMBER>/<AWSREGION>
```

Our account begins to bootstrap through the terminal.

![image](https://user-images.githubusercontent.com/119984652/235303708-cac9ae0c-4d2c-44c6-9622-3010ffcb34f5.png)

Next, we move over to the AWS console and view CloudFormation. Our `CDKToolkit` stack has been created.

![image](https://user-images.githubusercontent.com/119984652/235303867-a7d8f034-6d14-49db-bc19-3aa5e14011c6.png)

If we view our resources, we can see everything deployed to the stack. 

![image](https://user-images.githubusercontent.com/119984652/235305738-4baa6fe9-676a-4759-a415-81a871e48fa8.png)

We can now deploy our stack.

```sh
cdk deploy
```

![image](https://user-images.githubusercontent.com/119984652/235305808-048f55d8-74ec-4ef2-87a3-4a3e7f75837e.png)

This will generate a CloudFormation stack. Back over in CloudFormation, we look at this:

![image](https://user-images.githubusercontent.com/119984652/235305932-ef1f4765-c9f0-4326-8b72-59f19f8971bc.png)

We now move back over to our workspace and begin with our Lambda function. We first import `lambda` to our `thumbing-serverless-cdk-stack.ts` file. 

```ts
import * as lambda from 'aws-cdk-lib/aws-lambda';
```

Then we create a Lambda function to return a Lambda function.

```ts
createLambda(): lambda.IFunction {
  const lambdaFunction = new lambda.Function(this, 'ThumbLambda', {
    runtime: lambda.Runtime.NODEJS_18_X,
    handler: 'index.handler',
    code: lambda.Code.fromAsset(functionPath)
  });
```

We specify several parameters here. Again, `this` is the Construct object that the Lambda function will be a part of. `ThumbLamdba` is the name of the function in the CloudFormation stack. The `runtime` is the runtime of our environment. In this instance, we chose Node.js 18.x. The `handler` is the name of the handler function that will be invoked when the Lambda function is triggered. The `code` is the source code of our Lambda function. We haven't defined a variable for this yet, so we enter a placeholder of `functionPath` for the time being. 

We now define that function. 

```ts
const functionPath: string = process.env.THUMBING_FUNCTION_PATH as string;
```

Now we have to pass this into our `createLambda` function, then return the `lambdaFunction`.

```ts
createLambda(functionPath: string): lambda.IFunction {
  const lambdaFunction = new lambda.Function(this, 'ThumbLambda', {
    runtime: lambda.Runtime.NODEJS_18_X,
    handler: 'index.handler',
    code: lambda.Code.fromAsset(functionPath)
  });
  return lambdaFunction;
```

Kristi notes we could deploy now if we wanted to, as all requirements of CDK are met. Just to get a visual of what that would look like, we `cdk synth` again.

![image](https://user-images.githubusercontent.com/119984652/235313074-51901db6-c3fa-4040-b308-b2dc7e46160d.png)

Our bucket is there, but not our lambda. We need to define the lambda.

```ts
const lambda = this.createLambda(functionPath);
```

We again run `cdk synth`. 

![image](https://user-images.githubusercontent.com/119984652/235313215-6f32d16e-dfd3-4b3e-a261-e9a69205aa16.png)

We're seeing an error. Kristi says this is due to the fact we haven't defined our environment variables yet where we're using `bucketName` and `functionPath` as strings. To fix this, we create a new `.env` file in our `thumbing-serverless-cdk` directory. In the `.env` file, we begin defining our env vars. 

```.env
THUMBING_BUCKET_NAME="jh-cruddur=thumbs"
THUMBING_FUNCTION_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas"
```

Kristi lets us know this is just temporary to get the code working for now. Later, we will put these variables elsewhere once the Lambda is created. We again try to `cdk synth` but this time we get a `ERR_INVALID_ARG_TYPE` error. We come to find out after trying to `console.log(functionPath)` that it came back undefined. We still need to load our environment variables from the `.env` file we created. In our code we do this:

```ts
// Load env variables
const dotenv = require('dotenv')
dotenv.config();
```

Again we `cdk synth` and again we get a new error:

![image](https://user-images.githubusercontent.com/119984652/235313978-0a7ec9a5-9b87-4196-9157-1ec8ba087d27.png)

We need to load the module into our environment for `dotenv`.

```sh
npm i dotenv
```

From our `package.json` file, we check the `"dependencies"`. It's now listed.

![image](https://user-images.githubusercontent.com/119984652/235314150-9ba95dd6-5dc4-46b4-9c43-b6bbb3e52aa2.png)

We alter how we're loading our environmental variables by commenting out a line.

```ts
// Load env variables
//const dotenv = require('dotenv')
dotenv.config();
```

We again `cdk synth`. This time it completes successfully.

![image](https://user-images.githubusercontent.com/119984652/235315816-5a8a8327-ebce-4237-a137-d0285af2a374.png)

Our Lambda is here as well:

![image](https://user-images.githubusercontent.com/119984652/235315990-905903a4-eb19-4a17-986b-175ed3f6d64a.png)

Kristi tells us this is the benefit of CDK. If we were doing this in CloudFormation, this entire template would have to be written. We've completed the same using CDK with literally nothing more than this code:

```ts
createLambda(functionPath: string): lambda.IFunction {
  const lambdaFunction = new lambda.Function(this, 'ThumbLambda', {
    runtime: lambda.Runtime.NODEJS_18_X,
    handler: 'index.handler',
    code: lambda.Code.fromAsset(functionPath)
  });
  return lambdaFunction;
```

We continue on, now defining a few environment variables for our Lambda function. 

```ts
createLambda(functionPath: string, bucketName: string, folderInput: string, folderOutput: string): lambda.IFunction {
  const lambdaFunction = new lambda.Function(this, 'ThumbLambda', {
    runtime: lambda.Runtime.NODEJS_18_X,
    handler: 'index.handler',
    code: lambda.Code.fromAsset(functionPath),
    environment: {
      DEST_BUCKET_NAME: bucketName,
      FOLDER_INPUT: folderInput,
      FOLDER_OUTPUT: folderOutput,
      PROCESS_WIDTH: '512',
      PROCESS_HEIGHT: '512'
    }
  });
  return lambdaFunction;
```

Next we must define the variables we passed, as we have not defined them yet. 

```ts
const bucketName: string = process.env.THUMBING_BUCKET_NAME as string;
const functionPath: string = process.env.THUMBING_FUNCTION_PATH as string;
const folderInput: string = process.env.THUMBING_S3_FOLDER_INPUT as string;
const folderOutput: string = process.env.THUMBING_S3_FOLDER_OUTPUT as string;

const bucket = this.createdBucket(bucketName);
const lambda = this.createLambda(functionPath, bucketname, folderInput, folderOutput);
```

Then, we have to add the env vars to our `.env` file.

```.env
THUMBING_BUCKET_NAME="jh-cruddur=thumbs"
THUMBING_FUNCTION_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas"
THUMBING_S3_FOLDER_INPUT="avatars/original"
THUMBING_S3_FOLDER_OUTPUT="avatars/processed"
```

That completed our implementation with Kristi who did an awesome job guiding us through. Her explanations on what we were doing while doing it was extremely informative and helpful. Picking up where Kristi left off, Andrew continues on with us. He notes we did not yet add the install of CDK to our `.gitpod.yml` file. We navigate to our `.gitpod.yml` file and add the installation.

```yml
  - name: cdk
    before: |
      npm install aws-cdk -g
```

The next time we start up our environment, `cdk` will be installed. For now, we perform the install through our terminal. 

```sh
npm install aws-cdk -g
```

We attempt a `cdk deploy`. 

![image](https://user-images.githubusercontent.com/119984652/235317681-2d0f6868-66b3-492f-a3ff-89422192220c.png)

Andrew explains this is happening because we need to do an `npm install` in that directory as well. To fix this, we update our `.gitpod.yml` file. 

```yml
  - name: cdk
    before: |
      npm install aws-cdk -g
      cd thumbing-serverless-cdk   
      npm i  
```

For now, we manually do the `npm install`. Then we again attempt a `cdk deploy`. 

![image](https://user-images.githubusercontent.com/119984652/235317877-d08c92a6-7885-478d-a1b8-eed0d9ef6541.png)

This is again about our environment variables. Since our `.env` file does not persist between workspace launches, those environment variables do not exist anymore. To remedy this, we create a new file in the root of our workspace named `env.example`. From there, we go back to our `thumbing-serverless-cdk-stack.ts` file and add more of our env vars and `console.log` them out.

```ts
const bucketName: string = process.env.THUMBING_BUCKET_NAME as string;
const folderInput: string = process.env.THUMBING_S3_FOLDER_INPUT as string;
const folderOutput: string = process.env.THUMBING_S3_FOLDER_OUTPUT as string;
const webhookUrl: string = process.env.THUMBING_WEBHOOK_URL as string;
const topicName: string = process.env.THUMBING_TOPIC_NAME as string;
const functionPath: string = process.env.THUMBING_FUNCTION_PATH as string;
console.log('bucketName',bucketName)
console.log('folderInput',folderInput)
console.log('folderOutput',folderOutput)
console.log('webhookUrl',webhookUrl)
console.log('topicName',topicName)
console.log('functionPath',functionPath)
```

Back in our `.env.example` file, we define our variables.

```
THUMBING_BUCKET_NAME="assets.thejoshdev.com"
THUMBING_S3_FOLDER_INPUT="avatars/original"
THUMBING_S3_FOLDER_OUTPUT="avatars/processed"
THUMBING_WEBHOOK_URL="api.thejoshdev.com/webhooks/avatars"
THUMBING_TOPIC_NAME="cruddur-assets"
THUMBING_FUNCTION_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas/process-image"
```

We then create a new folder in our `/workspace/aws-bootcamp-cruddur-2023/aws/lambdas/` path named `process-images`. Also, we must pass these variables through our `.gitpod.yml` file. 

```yml
  - name: cdk
    before: |
      npm install aws-cdk -g
      cd thumbing-serverless-cdk   
      cp .env.example .env
      npm i  
```

From our terminal, we manually run the command added above.

```sh
cp .env.example .env
```

Then we again attempt a `cdk deploy`.

![image](https://user-images.githubusercontent.com/119984652/235321983-d0f08bed-cba7-4ded-853d-68be1d7c8de6.png)

When this does not work, Andrew lets us know that it could be due to the contents of the `process-images` folder not having any source code to pull from. I believe the real reason this did not work is due to the path we passed in the naming of the THUMBING_FUNCTION_PATH variable. We created a `process-images` folder, but the path does not match that. In following along with instruction however, we go to Andrew's branch of his repository where this is completed and grab the contents of that repo's `process-images` folder, beginning with `index.js`

```js
const process = require('process');
const {getClient, getOriginalImage, processImage, uploadProcessedImage} = require('./s3-image-processing.js')

const bucketName = process.env.DEST_BUCKET_NAME
const folderInput = process.env.FOLDER_INPUT
const folderOutput = process.env.FOLDER_OUTPUT
const width = parseInt(process.env.PROCESS_WIDTH)
const height = parseInt(process.env.PROCESS_HEIGHT)

client = getClient();

exports.handler = async (event) => {
  console.log('event',event)

  const srcBucket = event.Records[0].s3.bucket.name;
  const srcKey = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
  console.log('srcBucket',srcBucket)
  console.log('srcKey',srcKey)

  const dstBucket = bucketName;
  const dstKey = srcKey.replace(folderInput,folderOutput)
  console.log('dstBucket',dstBucket)
  console.log('dstKey',dstKey)

  const originalImage = await getOriginalImage(client,srcBucket,srcKey)
  const processedImage = await processImage(originalImage,width,height)
  await uploadProcessedImage(dstBucket,dstKey,processedImage)
};
```

Andrew notes the `exports.handler`, its the entry point of the Lambda. He then notes the `const srcBucket = event.Records[0].s3.bucket.name;` structure is predefined by the S3 bucket event notifications. Andrew shows us through the AWS Console under an S3 bucket where the notifications would be.

![image](https://user-images.githubusercontent.com/119984652/235319159-c3a0790e-2468-418c-a373-598e268954e0.png)

Further down in the code, `Records[0].s3.object.key` is not going to pass multiple records, just a single record Andrew explains. It then gets the `srcKey`. 

```js
const srcKey = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
```

Then we're replacing the `folderInput` with the `folderOutput`. 

```js
const dstKey = srcKey.replace(folderInput,folderOutput)
```

Andrew said the idea is the `dstKey` will come back with the target, .i.e. `/avatar/original/Image.jpg` replaced by `/avatar/processed/Image.jpg`. 

Further down, it will find the `originalImage`, pass it onto the `processedImage`, then it will upload `uploadProcessedImage`.

```js
  const originalImage = await getOriginalImage(client,srcBucket,srcKey)
  const processedImage = await processImage(originalImage,width,height)
  await uploadProcessedImage(client,dstBucket,dstKey,processedImage)
```

This is abstracted into a class.

```js
const {getClient, getOriginalImage, processImage, uploadProcessedImage} = require('./s3-image-processing.js')
```

This all needed to be tested, so an additional file was made in `./aws/lambdas/process-images` called `test.js`

```js
const {getClient, getOriginalImage, processImage, uploadProcessedImage} = require('./s3-image-processing.js')

async function main(){
  client = getClient()
  const srcBucket = 'cruddur-thumbs'
  const srcKey = 'avatar/original/data.jpg'
  const dstBucket = 'cruddur-thumbs'
  const dstKey = 'avatar/processed/data.png'
  const width = 256
  const height = 256

  const originalImage = await getOriginalImage(client,srcBucket,srcKey)
  console.log(originalImage)
  const processedImage = await processImage(originalImage,width,height)
  await uploadProcessedImage(client,dstBucket,dstKey,processedImage)
}

main()
```

Andrew explains this is very similar to our `index.js` except the values are all hard coded here to rule out any event data issues. We next create our `s3-image-processing.js` file. 

```js
const sharp = require('sharp');
const { S3Client, PutObjectCommand, GetObjectCommand } = require("@aws-sdk/client-s3");

function getClient(){
  const client = new S3Client();
  return client;
}

async function getOriginalImage(client,srcBucket,srcKey){
  console.log('get==')
  const params = {
    Bucket: srcBucket,
    Key: srcKey
  };
  console.log('params',params)
  const command = new GetObjectCommand(params);
  const response = await client.send(command);

  const chunks = [];
  for await (const chunk of response.Body) {
    chunks.push(chunk);
  }
  const buffer = Buffer.concat(chunks);
  return buffer;
}

async function processImage(image,width,height){
  const processedImage = await sharp(image)
    .resize(width, height)
    .png()
    .toBuffer();
  return processedImage;
}

async function uploadProcessedImage(client,dstBucket,dstKey,image){
  console.log('upload==')
  const params = {
    Bucket: dstBucket,
    Key: dstKey,
    Body: image,
    ContentType: 'image/png'
  };
  console.log('params',params)
  const command = new PutObjectCommand(params);
  const response = await client.send(command);
  console.log('repsonse',response);
  return response;
}

module.exports = {
  getClient: getClient,
  getOriginalImage: getOriginalImage,
  processImage: processImage,
  uploadProcessedImage: uploadProcessedImage
}
```

Here we get the client. The other functions require the client to work.

```js
function getClient(){
  const client = new S3Client();
  return client;
```

Sharp was chosen Andrew said because its a small library which didn't require Lambda layers. 

```js
const sharp = require('sharp');
```

For added reference, we copy a file into our `aws/lambdas/process-images` directory named `example.json` that was code generated by ChatGPT.

```json
{
  "Records": [
      {
          "eventVersion": "2.1",
          "eventSource": "aws:s3",
          "awsRegion": "us-east-1",
          "eventTime": "2023-04-04T12:34:56.000Z",
          "eventName": "ObjectCreated:Put",
          "userIdentity": {
              "principalId": "EXAMPLE"
          },
          "requestParameters": {
              "sourceIPAddress": "127.0.0.1"
          },
          "responseElements": {
              "x-amz-request-id": "EXAMPLE123456789",
              "x-amz-id-2": "EXAMPLE123/abcdefghijklmno/123456789"
          },
          "s3": {
              "s3SchemaVersion": "1.0",
              "configurationId": "EXAMPLEConfig",
              "bucket": {
                  "name": "example-bucket",
                  "ownerIdentity": {
                      "principalId": "EXAMPLE"
                  },
                  "arn": "arn:aws:s3:::example-bucket"
              },
              "object": {
                  "key": "example-object.txt",
                  "size": 1024,
                  "eTag": "EXAMPLEETAG",
                  "sequencer": "EXAMPLESEQUENCER"
              }
          }
      }
  ]
}
```

We need to load our dependencies, so from the terminal, we cd into our `./aws/lambdas/process-images` directory, then run `npm init -y` to create an empty `.init` file in the directory. We then install Sharp.

```sh
npm i sharpjs
```

When we check our `package.json` file, the dependencies aren't correct. 

![image](https://user-images.githubusercontent.com/119984652/235320407-15665ac5-fd58-4fa7-aba1-df7632e00985.png)

We delete the generated `node_modules` file from the directory manually. Then, we remove the `"sharpjs": "^0.1.11"` dependency. We then run the proper command.

```sh
npm i sharp
```

Our `package.json` file updates again.

![image](https://user-images.githubusercontent.com/119984652/235320493-26fb96b0-7791-495c-b4bf-c958febf3a58.png)

We also need the `aws-sdk/client-s3` module installed here as well. 

```sh
npm i @aws-sdk/client-s3
```

Andrew explains why the install for this has the `@` symbol added. It's due to the size of the `aws-sdk` package library. It's broken up into a bunch of subpackages so you can install exactly what you want, individually for the most part. 

Our `"dependencies"` updates in the `package.json` file.

![image](https://user-images.githubusercontent.com/119984652/235320639-b0d04724-c1b2-4420-ab90-cc1fe2ab6fb7.png)

We now come back to attempting a `cdk deploy`. 

![image](https://user-images.githubusercontent.com/119984652/235320718-95946416-4858-43d3-b565-7fcc613f1e57.png)

Andrew recognizes that the path given in our env var does not match the folder name `process-images`. We move back to our `.env.example` file and update the `THUMBING_FUNCTION_PATH` env var's path. 

```.env
THUMBING_FUNCTION_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas/process-images"
```

Then in our generated `.env` file we do the same.

```.env
THUMBING_FUNCTION_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas/process-images"
```

We again do a `cdk deploy`. This time it appears to be working.

![image](https://user-images.githubusercontent.com/119984652/235320894-c5c6cdf5-cb0a-4249-b9ea-c73007e9b629.png)

Then we're notified of the changes that are about to be made to our IAM.

![image](https://user-images.githubusercontent.com/119984652/235320957-da5d449e-49a8-4510-97a0-8274b6b30da3.png)

We allow this change. Our implementation proceeds.

![image](https://user-images.githubusercontent.com/119984652/235321000-a4b581a6-0a68-4dfb-97c5-e76ee6d51173.png)

When this completes, we go back over to the AWS Console and check the resources of the `ThumbingServerlessCdkStack` that we deployed.

![image](https://user-images.githubusercontent.com/119984652/235321069-5fc77e1a-3acc-4284-9c4f-ea2def584e96.png)

We verify that our Lambda was created, so we navigate over to Lambda. Due to the method of which it was created, our code is not editable inline as the file is too large.

![image](https://user-images.githubusercontent.com/119984652/235321157-a0f915fc-38e4-45b8-b674-be1262e399ef.png)

We need to ensure that SharpJS is installed for our Lambda to function correctly. Andrew explains to us that Sharp will not work installed as a Lambda layer either. I asked ChatGPT why this is, and this is what it told me. 

```
"The sharp library is a popular image processing library for Node.js applications. When using sharp in an AWS Lambda function, it's possible to encounter issues when attempting to package it as a Lambda Layer.

The reason for this is that sharp is a native Node.js module that depends on compiled binaries that are specific to the operating system and architecture of the system where it is installed. When you package sharp as a Lambda Layer, the compiled binaries may not be compatible with the target operating system and architecture of the Lambda environment. This can lead to runtime errors when attempting to use sharp in your Lambda function.

To work around this issue, it is recommended to package the sharp library directly into the Lambda deployment package along with your function code, rather than as a separate Lambda Layer. This ensures that the compiled binaries are compatible with the target environment."
```

Andrew takes us over to SharpJS's documentation and shows us that there's a particular way recommended to install for AWS Lambda. 

![image](https://user-images.githubusercontent.com/119984652/235321332-5125f4c4-29bd-496a-a476-e3a8fba35107.png)

From our terminal, we follow along with the documentation.

```sh
npm install
```

```sh
rm -rf node_modules/sharp
```

```sh
SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install --arch=x64 --platform=linux --libc-glibc sharp
```

Just so we do not lose this, we then create a new script and folder to house it in our `./bin` directory: `./bin/serverless/build`.

```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $SERVERLESS_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
SERVERLESS_PROJECT_PATH="$PROJECT_PATH/thumbing-serverless-cdk"

cd $SERVERLESS_PROJECT_PATH

npm install
rm -rf node_modules/sharp
SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install --arch=x64 --platform=linux --libc-glibc sharp
```

We aren't certain that `cd`'ing into that directory will work or not because it's changing the directory prior to running the command. We chmod the file to make it executeable, then run it. 

```sh
./bin/serverless/build
```

![image](https://user-images.githubusercontent.com/119984652/235321726-eafb4dcb-4c66-4df6-be78-c744a5756ad8.png)

The script completes without any issue. Moving on, Andrew says we need the SNS topic, but he said that we don't need it right away. What we do need is the input first. We're going to connect the S3 bucket to our Lambda. To do this, we're going to create an S3 Event notification to Lambda. In our `thumbing-serverless-cdk-stack.ts` file, we add the function call: 

```ts
this.createS3NotifyToLambda(folderInput,lambda,bucket);
```

Then add the function. This will create the `LambdaDestination`. We're passing in the Lambda, the S3 bucket, and the prefix. 

```ts
createS3NotifyToLambda(prefix: string, lambda: lambda.IFunction, bucket: s3.IBucket): void {
  const destination = new s3n.LambdaDestination(lambda);
  bucket.addEventNotification(
   s3.EventType.OBJECT_CREATED_PUT,
   destination,
   {prefix: prefix} // folder to contain the original images 
  )
}
```

We find that we were missing the import for `s3n` so we added this as well.

```ts
import * as s3n from 'aws-cdk-lib/aws-s3-notifications';
```

We `cd` over to our `thumbing-serverless-cdk` directory and again perform a `cdk synth`. With the output, Andrew copies it from the terminal and creates a temporary file called `test.yml` so we can get a better view of it. We find that another Lambda is being created. Andrew said this is likely being created as an intermediary way to get back to the S3 bucket.

![image](https://user-images.githubusercontent.com/119984652/235531853-294ef043-b544-4f70-b5b0-1770dfc7b2a5.png)

We perform a `cdk deploy`. We go back over to CloudFormation in the AWS console and review the resources of our stack again. There's now a `BucketNotificationsHandler` added.

![image](https://user-images.githubusercontent.com/119984652/235532997-275913b7-6b90-40ae-bd02-85a8aa43652b.png)

We also are interested in the Lambda, so we navigate over there and review. There's now a trigger to our S3 bucket. 

![image](https://user-images.githubusercontent.com/119984652/235533596-10452701-bf94-4c15-a20b-9d4183087a3f.png)

Andrew finds that his S3 bucket is still named `cruddur-thumbs` which was a previous deployment name of the bucket. Since we've updated the bucket name since then, CDK is not tearing down the existing bucket and creating a new one with deployments as originally thought. So instead, we do a `cdk destroy`. This will tear down every resource created from our stack in reverse order it was created. 

![image](https://user-images.githubusercontent.com/119984652/235534346-6244429a-16c8-4b17-89b0-6ea2d7ce62b7.png)

Once our stack is destroyed, we again do a `cdk deploy`. We again check the Lambda created by our deployment. Andrew's bucket is again named `cruddur-thumbs`. After reviewing his AWS console and navigating to S3, Andrew believes he remembers the issue and goes back to his workspace. From there, he does a `env | grep THUMB` to check his env vars stored to GitPod, our workspace. 

![image](https://user-images.githubusercontent.com/119984652/235535053-c3b4dcd3-065b-4210-b0bd-e27a58280a98.png)

Andrew had variables stored for this. He unsets the variables, then removes them. Andrew again does a `cdk deploy`. He did not do a `cdk destroy` first this time on purpose. It was so we could see if the changesets in CDK will deploy the updated S3 bucket name since it's not deploying based on the env var set from our workspace. 

This fixed the issue.

![image](https://user-images.githubusercontent.com/119984652/235535442-5c310b30-084e-465a-adad-4d108b7f4c13.png)

![image](https://user-images.githubusercontent.com/119984652/235535570-b400dc3f-712b-4a59-8596-32e01229c62e.png)

We navigate to CloudFormation to double check and be sure. That confirms it fixed the issue.

![image](https://user-images.githubusercontent.com/119984652/235535745-44d0090a-c859-4861-bb1a-814abc2722bc.png)

While here, we review the changesets, in particular the latest one. You can see the bucket is being updated.

![image](https://user-images.githubusercontent.com/119984652/235536163-8f82166c-6d5d-4827-8421-b0664c7fa7d1.png)

We want to import our existing bucket into the stack. Back in our workspace, we again tear down our stack.

```sh
cdk destroy
```

We create a new function in our `thumbing-serverless-cdk-stack.ts` file.

```ts
  importBucket(bucketName: string): s3.IBucket {
    const bucket = s3.Bucket.fromBucketName(this,"AssetsBucket",bucketName);
    return bucket;
  }
```

The `id` or logical name of the bucket is actually `AssetsBucket` or that makes more sense than `ThumbingBucket`. We update our existing code referencing `ThumbingBucket` to `AssetsBucket` as well. 

Our `const bucket` we set previously must now be updated to reference importing the existing bucket. 

```ts
//const bucket = this.createBucket(bucketName);
const bucket = this.importBucket(bucketName);
```

We manually create the bucket through S3 in the AWS console. 

![image](https://user-images.githubusercontent.com/119984652/235537946-61690e1a-1668-4cb6-bfbb-16a29063b030.png)

Back in our workspace, we do a `cdk deploy`. We again review CloudFormation and look at our resources. We see the bucket is added there. Just to make sure the bucket will persist even though the rest of the stack will be torn down, we do a `cdk destroy`. Once the stack is completely torn down, we again reference our S3 bucket, and it's still there. We select the bucket, then we create two new folders. `original/` and `processed/`. 

![image](https://user-images.githubusercontent.com/119984652/235538750-f96c79cc-3baa-4422-bd24-9e3b3c25f50d.png)

We save an image to work with, making sure it's dimensions are big enough for us to restructure the image during processing. We upload the image to our `oringal/` folder in S3. This should've triggered our Lambda function to process the image. We decide to check this, so we navigate over to Lambda in the AWS console. The Lambda does not exist. We remember that we left our stack torn down. Instead of manually uploading the image, we decide to write some CLI commands, since we're going to be working with this for a bit. 

We do a `cdk deploy`. With our stack deployed, we move onto the scripts we were going to create. From our `./bin/serverless/` directory, we create `upload`, which is referencing an env var `$DOMAIN_NAME` we've setup locally in our workspace. 

```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
DATA_FILE_PATH="$SERVERLESS_PATH/files/data.jpg"

aws s3 cp "$DATA_FILE_PATH" "s3://assets.$DOMAIN_NAME"
```

We create a new folder in our `./bin/serverless` directory named `Files` and upload our image to it.

![image](https://user-images.githubusercontent.com/119984652/235540550-10a6c2d9-8e82-4195-9ba7-d6fe7e15b4bf.png)


We chmod `./bin/serverless/upload` to make it executable. Then we run the file to test it out. 

```sh
./bin/serverless/upload
```

We navigate back over to S3 in AWS to check our bucket and see if the upload worked. It did, we just didn't specify the correct folder.

![image](https://user-images.githubusercontent.com/119984652/235541262-c06355dc-5a89-42bd-9fd4-cac567e09909.png)

We delete the image from our bucket, then we go back to our workspace to review the path. 

```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
DATA_FILE_PATH="$SERVERLESS_PATH/files/data.jpg"

aws s3 cp "$DATA_FILE_PATH" "s3://assets.$DOMAIN_NAME/avatar/original"
```

We realize the folders in S3 are set to be top level instead of inside of a folder, so we delete them from the S3 bucket. We also decide to rename the main folder, as it will contain multiple avatars, not just one. We update our `./thumbing-serverless-cdk/.env.example` file as it holds our env vars set for this. 

```.env
THUMBING_S3_INPUT="avatars/original"
THUMBING_S3_OUTPUT="avatars/processed"
```

We update the same in our `.env` file as well. We also update the path in our `upload` script. 

```sh
aws s3 cp "$DATA_FILE_PATH" "s3://assets.$DOMAIN_NAME/avatars/original"
```

We do another `cdk deploy`. Then, we create another script. This one will be to remove the image. We create `./bin/serverless/clear`. 

```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
DATA_FILE_PATH="$SERVERLESS_PATH/files/data.jpg"

aws s3 rm "s3://assets.$DOMAIN_NAME/avatars/original/data.jpg"
aws s3 rm "s3://assets.$DOMAIN_NAME/avatars/processed/data.png"
```

We run our `upload` file.

```sh
./bin/serverless/upload
```

We refresh S3 from AWS. We now have a file named `original`.

![image](https://user-images.githubusercontent.com/119984652/235546930-76c35364-d317-4eb3-be60-1a0bf33563e5.png)

We next check S3 for our event notification. It's there, listed as event type: `put`. 

![image](https://user-images.githubusercontent.com/119984652/235547127-8222f903-26c0-4779-a7ae-0c70eb1d73e2.png)

We next check our S3 buckets to see if the image processed. It did not, so we review the Lambda. We review the Cloudwatch logs for the Lambda and find that there aren't any. Andrew believes this is because we're doing a `put` and not a `post`. We go back to `thumbing-serverless-cdk-stack.ts` and update our function. 

```ts
  createS3NotifyToLambda(prefix: string, lambda: lambda.IFunction, bucket: s3.IBucket): void {
    const destination = new s3n.LambdaDestination(lambda);
    bucket.addEventNotification(
      s3.EventType.OBJECT_CREATED_POST,
      destination//,
      //{prefix: prefix} // folder to contain the original images
    )
  }
```

Again, we re-deploy with a `cdk deploy`. We then use our `clear` script created earlier. 

```sh
./bin/serverless/clear
```

When we check to see if this completed successfully in S3, that's when it's noticed that `avatars/original` generated a file and not an image in our bucket. We manually delete the file, then go back to our `./bin/serverless/upload` script and edit the file path. 

```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
DATA_FILE_PATH="$SERVERLESS_PATH/files/data.jpg"

aws s3 cp "$DATA_FILE_PATH" "s3://assets.$DOMAIN_NAME/avatars/original/data.jpg"
```

At this point, Andrew believes the Lambda would've worked with a `put` as well as a `post`. The difference is going to be the event data returned. We run our `upload` script again.

```sh
./bin/serverless/upload
```

Back in S3, we take a look at our bucket again.

![image](https://user-images.githubusercontent.com/119984652/235548412-75f3f128-a024-4b06-9cef-a015d568204e.png)

Looks like our `original` folder created, but our Lambda didn't run to process the image, so there's no `processed` folder. No Cloudwatch logs for the Lambda either. Andrew thinks this is likely due to that event data being returned as he mentioned earlier, so we change our function back to a `put`. 

```ts
  createS3NotifyToLambda(prefix: string, lambda: lambda.IFunction, bucket: s3.IBucket): void {
    const destination = new s3n.LambdaDestination(lambda);
    bucket.addEventNotification(
      s3.EventType.OBJECT_CREATED_PUT,
      destination//,
      //{prefix: prefix} // folder to contain the original images
    )
  }
```

We clear our S3 bucket.

```sh
./bin/serverless/clear
```

Then re-deploy.

```sh
cdk deploy
```

Then we attempt to upload an image again. 

```sh
./bin/serverless/upload
```

Back in S3, again, our `original/` folder is created, but not `processed/`. Also there's still no Cloudwatch logs for the Lambda. We decide to test and see if just the Lambda itself works. In Lambda from the AWS console, we go to Test. We already have `example.json` created earlier with some test data we can add. We paste `example.json` into the Event JSON field:

```json
{
    "Records": [
      {
        "eventVersion": "2.0",
        "eventSource": "aws:s3",
        "awsRegion": "us-east-1",
        "eventTime": "1970-01-01T00:00:00.000Z",
        "eventName": "ObjectCreated:Put",
        "userIdentity": {
          "principalId": "EXAMPLE"
        },
        "requestParameters": {
          "sourceIPAddress": "127.0.0.1"
        },
        "responseElements": {
          "x-amz-request-id": "EXAMPLE123456789",
          "x-amz-id-2": "EXAMPLE123/5678abcdefghijklambdaisawesome/mnopqrstuvwxyzABCDEFGH"
        },
        "s3": {
          "s3SchemaVersion": "1.0",
          "configurationId": "testConfigRule",
          "bucket": {
            "name": "assets.thejoshdev.com",
            "ownerIdentity": {
              "principalId": "EXAMPLE"
            },
            "arn": "arn:aws:s3:::assets.thejoshdev.com"
          },
          "object": {
            "key": "avatars/original/data.jpg",
            "size": 1024,
            "eTag": "0123456789abcdef0123456789abcdef",
            "sequencer": "0A1B2C3D4E5F678901"
          }
        }
      }
    ]
  }
```

We hit test, and get an "Execution result: failed".

![image](https://user-images.githubusercontent.com/119984652/235549507-b5d4d06d-9a74-4bd2-a1b6-5414914c94fa.png)

We think it might be a problem with our data. So we try a template offered by AWS of `s3-put`. This test fails as well. 

![image](https://user-images.githubusercontent.com/119984652/235549656-496cede4-1fc4-48f8-931e-6b3731947f1a.png)

In reviewing our permissions for the Lambda, we realize it might not have permissions to the S3 bucket. We navigate over to `thumbing-serverless-cdk-stack.ts` and create a policy for bucket access.

```ts
    const s3ReadWritePolicy = this.createPolicyBucketAccess(uploadsBucket.bucketArn)
```

We also create a function:

```ts
  createPolicyBucketAccess(bucketArn: string){
    const s3ReadWritePolicy = new iam.PolicyStatement({
      actions: [
        's3:GetObject',
        's3:PutObject',
      ],
      resources: [
        `${bucketArn}/*`,
      ]
    });
    return s3ReadWritePolicy;
  }
```

We also need to import `iam` now. 

```ts
import * as iam from 'aws-cdk-lib/aws-iam';
```

Next we must attach the policy to the Lambda. 

```ts
lambda.addToRolePolicy(s3ReadWritePolicy);
```

Again, we deploy.

```sh
cdk deploy
```

Again we go back to our Lambda and check the permissions. It looks like this might resolve our issue with uploads. We now have S3 permissions for the Lambda.

![image](https://user-images.githubusercontent.com/119984652/235550740-13a82ae5-b007-47b7-87f5-dc7bdc0df2c2.png)

We make sure our bucket is empty.

```sh
./bin/serverless/clear
```

Then we again attempt to upload an image.

```sh
./bin/serverless/upload
```

We check our S3 bucket and we again have our `original/` folder, but no `processed/`. There's also now a Cloudwatch log.

![image](https://user-images.githubusercontent.com/119984652/235551195-9964073c-4a25-4867-bfd1-85b231795c50.png)

This Cloudwatch log is from the Test code from our Lambda. We run the `s3-put` test code again and it fails again, but in reviewing the Cloudwatch logs, we may have found something. This is from the Cloudwatch log:

![image](https://user-images.githubusercontent.com/119984652/235552444-fca3cd7a-0640-4362-9484-9558e736267d.png)

In our `./aws/lambdas/process-images/index.js` file, one of our `const`'s: 

![image](https://user-images.githubusercontent.com/119984652/235552587-3c46101c-f5d0-4a5d-80c9-be3418e291a2.png)

That leads us to review the env vars set for our Lambda. 

![image](https://user-images.githubusercontent.com/119984652/235552807-89ad32fa-ab9f-42b9-b36e-587eeba4b17b.png)

In comparing the env vars with what's being passed as the `srcKey`, you can see that we don't need the beginning `"/"`. 

We go back to our `.env.example` env vars to remove it. 

```.env
THUMBING_S3_FOLDER_INPUT="avatars/original"
THUMBING_S3_FOLDER_OUTPUT="avatars/processed"
```

We update our `.env` file as well. We again `cdk deploy`. Then, we run `./bin/serverless/clear` to clear the S3 bucket, and `./bin/serverless/upload` to upload an image again. We check S3 and find the same situation as before. `original/` folder is there. However, we do have a new Cloudwatch log.

![image](https://user-images.githubusercontent.com/119984652/235553362-f7f9f4c9-4f2c-4861-8563-f10d0cf168f8.png)

We go back to our code to find the issue. In `./aws/lambdas/process-images/s3-image-processing.js`, we find `client.send`. 

![image](https://user-images.githubusercontent.com/119984652/235553558-41df221a-7d3d-41e5-8c0e-078f2adb5071.png)

The error in the Cloudwatch log indicated we're missing the client, so we go back to In `./aws/lambdas/process-images/index.js` and find that we need to add it to `uploadProcessedimage`. 

```js
  const originalImage = await getOriginalImage(client,srcBucket,srcKey)
  const processedImage = await processImage(originalImage,width,height)
  await uploadProcessedImage(client,dstBucket,dstKey,processedImage)
```

We again `cdk deploy`. Then, `./bin/serverless/clear` and `./bin/serverless/upload`. Next, we check again through S3. We now have a `processed/` folder!

![image](https://user-images.githubusercontent.com/119984652/235554083-4ec6d67f-d3b4-4906-a7ec-5891ddeb370f.png)

Something still isn't correct however. The image is of `.jpg` format. Yet, in our `s3-iamge-processing.js` file, it's supposed to be `.png`. 

![image](https://user-images.githubusercontent.com/119984652/235554242-baa13cc5-a2e9-4296-a2da-6060989dca78.png)

We download the image from S3 to see if the properties will tell us anything. The image downloads as a `.png` file. 

We decide instead to remove the file extension in our code. From our `./aws/lambdas/process-images/index.js` file:

```js
const path = require('path');

  filename = path.parse(srcKey).name
  const dstKey = `${folderOutput}/${filename}.png`;
```

Per ChatGPT, this is what the code here is doing: 

"We require `path` module from Node.js and assign it the variable `'path'`. We use the `path.parse()` method to extract the file name from `srcKey`, our input string. It returns an object that contains the different parts of the path, such as the file name, directory, and extension. The `.name` property of the returned object contains only the file name without the extension. 

The extracted file name is then assigned to the variable filename.

Finally, a new string `dstKey` is created by concatenating the `folderOutput` string, a forward slash "/", the filename variable, and the `.png` file extension. This new string represents the output file path where the file will be saved as a PNG image file."

After these changes, we again `cdk deploy`. We again clear our S3 bucket with `./bin/serverless/clear`, but we manually clear the S3 bucket from the AWS console as well. We run `./bin/serverless/upload`. We move back over the CloudWatch in the AWS console. We view the latest log:

![image](https://user-images.githubusercontent.com/119984652/235790356-81129ec0-6685-4b75-a95b-03870239d74d.png)

Our image is being set correctly. We have instead decided however that we want the image to be a `.jpg`. We update the file extension in `./bin/serverless/clear`.

```sh
aws s3 rm "s3://assets.$DOMAIN_NAME/avatars/processed/data.jpg"
```

We move back over to `./aws/lambdas/process-images/s3-image-processing.js` and update the `ContentType` on our `uploadProcessedImage` function to `image/jpeg`.

![image](https://user-images.githubusercontent.com/119984652/235792005-5771dacf-061f-4c1e-b661-1846a227b04c.png)

We also update the `processimage` function:

```js
async function processImage(image,width,height){
 const processedImage = await sharp(image)
   .resize(width, height)
   .jpeg()
   .toBuffer();
 return processedImage;
 }
```

Above we set the output format of the image to `.jpeg` by calling the `jpeg()` method on the `sharp` instance. 

We also update `./aws/lambdas/process-images/index.js`:

```js
const path = require('path');

  filename = path.parse(srcKey).name
  const dstKey = `${folderOutput}/${filename}.jpg`;
```

We again clear our S3 bucket, then `cdk deploy`. After this, we again run `./bin/serverless/upload`. When we reference our S3 bucket this time, we now have `data.jpg` in the `avatars/processed/` folder. 

![image](https://user-images.githubusercontent.com/119984652/235797159-d3807a9f-c612-4dd4-b421-8435210e5b34.png)

We now need to send data on the way out. This will be our notification. We must create an SNS Topic, an SNS subscription, and an S3 Event Notification to SNS. We navigate to our `thumbing-serverless-cdk-stack.ts` file and begin with our SNS topic. 

We add the import statements for the SNS topic and subscriptions. 

```js
import * as sns from 'aws-cdk-lib/aws-sns';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
```

Then we create the topic. Then we create the SNS subscription. We also add the policy for SNS publishing. We attach the policy to the Lambda role as well. 

```js
const snsTopic = this.createSnsTopic(topicName)
this.createSnsSubscription(snsTopic,webhookUrl)
const snsPublishPolicy = this.createPolicySnSPublish(snsTopic.topicArn)

lambda.addToRolePolicy(snsPublishPolicy);
```

We next create the SNS topic:

```js
createSnsTopic(topicName: string): sns.ITopic{
  const logicalName = "ThumbingTopic";
  const snsTopic = new sns.Topic(this, logicalName, {
    topicName: topicName
  });
  return snsTopic;
```

And the SNS subscription:

```js
createSnsSubscription(snsTopic: sns.ITopic, webhookUrl: string): sns.Subscription {
  const snsSubscription = snsTopic.addSubscription(
    new subscriptions.UrlSubscription(webhookUrl)
  )
  return snsSubscription;
}
```

We also create an S3 Event Notification to SNS:

```js
createS3NotifyToSns(prefix: string, snsTopic: sns.ITopic, bucket: s3.IBucket): void {
  const destination = new s3n.SnsDestination(snsTopic)
  bucket.addEventNotification(
    s3.EventType.OBJECT_CREATED_PUT,
    destination,
    {prefix: prefix}
  );
}
```

We clean up our code, and organize it for easier reading.

![image](https://user-images.githubusercontent.com/119984652/235801740-76b2faac-42b5-4fe3-8bbd-75cddb2562f5.png)

We clear our S3 bucket, then `cdk deploy`. With the amount of code we just updated, we have an error.  

![image](https://user-images.githubusercontent.com/119984652/235801176-88dafdbf-dbc7-418e-8cc3-7745d68fabe5.png)

We check our `.env.example` file and see that is our problem. We update the `THUMBING_WEBHOOK_URL` variable to `"https://api.thejoshdev.com/webhooks/avatar"` then update our `.env` file the same. We again `cdk deploy`. We then head back over to AWS S3 and check our bucket properties to view the event notifications.

![image](https://user-images.githubusercontent.com/119984652/235802254-93b263bb-c132-41bd-95a8-f71d4769e472.png)

Our implementation is working thus far. We're now going to work on serving our images, i.e. assets over AWS Cloudfront. We move over to Cloudfront and click "Create a CloudFront distribution". We set an Origin Domain, Name, and set an Origin access control. Then we set Viewer protocol policy to "Redirect HTTP to HTTPS", and set the Cache policy to "CachingOptimized" and the Origin request policy to "CORS-CustomOrigin".  

![image](https://user-images.githubusercontent.com/119984652/235804849-ced52aa2-cfce-4571-9548-aedb02137c1a.png)

![image](https://user-images.githubusercontent.com/119984652/235804886-24902653-02f8-4347-abde-899f2d43bdd3.png)

Moving on, we set the Response headers policy to "SimpleCORS", left real-time logs off to save on spend, and added our CNAME record, in my case `assets.thejoshdev.com` as the alternate domain name. Then we added our ACM certificate as the custom SSL certificate. Since my region is already `us-east-1`, I can use my ACM certificate here without having to make another. Other regions have to create one for the `us-east-1` region to use here. We added a description of "Serve Assets for Cruddur" so we know what this does, then created the distribution. 

![image](https://user-images.githubusercontent.com/119984652/235805997-93d4bb4d-9a7c-46c1-8d15-2b5055c94142.png)

Cloudfront generates out a distribution domain name when it completes. When we attempt to navigate to our endpoint, the page does not load. Andrew believes we need to add a new record to Route53 and that should resolve the issue. We navigate over to Route53 then go to Hosted Zones. We then create the record to point `assets.thejoshdev.com` to our CloudFront distribution domain. 

![image](https://user-images.githubusercontent.com/119984652/235807001-0dfeda24-406a-4d6b-b337-029417d2978f.png)

When we attempt to navigate here via the browser, it's giving us an error. As it turns out, when setting up the CloudFront distribution, we forgot to setup the bucket policy. We navigate over the S3 and do so now for our bucket. We select our assets bucket, then go to the Permissions tab and view the Bucket Policy, then select Edit. We provide the following JSON:

```json
{
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::assets.thejoshdev.com/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::99999999999999:distribution/ESEXETEF7X5THX"
                }
            }
        }
    ]
}
```

We then test our endpoint again. It now loads without issue.

![image](https://user-images.githubusercontent.com/119984652/235807908-d9ead115-d9e0-437b-8dec-2ed367b2dcec.png)

We decide to lock down access to our original images, and in doing so, we've decided we're going to have another bucket created. This way, one bucket contains our uploaded images, the other will contain the processed ones. 

We add a edit our variables by adding one and altering one in our `.env.example` and `.env` files: 

```.env
UPLOADS_BUCKET_NAME="thejoshdev-uploaded-avatars"
ASSETS_BUCKET_NAME="assets.thejoshdev.com"
```

We go back over to `thumbing-serverless-cdk-stack.ts` and add code to create new buckets:

```ts
    // The code that defines your stack goes here
    const uploadsBucketName: string = process.env.UPLOADS_BUCKET_NAME as string;
    const assetsBucketName: string = process.env.ASSETS_BUCKET_NAME as string;
    
    const uploadsBucket = this.createBucket(uploadsBucketName);
    const assetsBucket = this.importBucket(assetsBucketName);
```

We update our Lambda to include the new buckets. 

```ts
    // create a lambda
    const lambda = this.createLambda(
      functionPath, 
      uploadsBucketName, 
      assetsBucketName, 
      folderInput, 
      folderOutput
    );
```

Then our S3 Event notifications.

```ts
    // add our s3 event notifications
    this.createS3NotifyToLambda(folderInput,lambda,uploadsBucket)
    this.createS3NotifyToSns(folderOutput,snsTopic,assetsBucket)
```

Next we update our policy, and add another.

```ts
    // create policies
    const s3UploadsReadWritePolicy = this.createPolicyBucketAccess(uploadsBucket.bucketArn)
    const s3AssetsReadWritePolicy = this.createPolicyBucketAccess(assetsBucket.bucketArn)
```

We update what's being passed to our `createLambda` function.

```ts
  createLambda(functionPath: string, uploadsBucketName: string, assetsBucketName: string, folderInput: string, folderOutput: string): lambda.IFunction {
    const lambdaFunction = new lambda.Function(this, 'ThumbLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(functionPath),
      environment: {
        DEST_BUCKET_NAME: assetsBucketName,
        FOLDER_INPUT: folderInput,
        FOLDER_OUTPUT: folderOutput,
        PROCESS_WIDTH: '512',
        PROCESS_HEIGHT: '512'
      }
    });
    return lambdaFunction;
  }
```

Then our `createBucket` and `importBucket` functions.

```ts
  createBucket(bucketName: string): s3.IBucket {
    const bucket = new s3.Bucket(this, 'UploadsBucket', {
      bucketName: bucketName,
      removalPolicy: cdk.RemovalPolicy.DESTROY
    });
    return bucket;
  }

  importBucket(bucketName: string): s3.IBucket {
    const bucket = s3.Bucket.fromBucketName(this,"AssetsBucket",bucketName);
    return bucket;
  }
```

With these changes, we again do a `cdk deploy`. In discussing our `./bin/serverless` directory, Andrew mentions he'd like to rename it to something a little more in tune with what the folder is for. We update it to `./bin/avatar` instead. With the new bucket names, we need to go update one of our scripts. The `./bin/avatars/upload` script.

```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
DATA_FILE_PATH="$SERVERLESS_PATH/files/data.jpg"

aws s3 rm "s3://thejoshdev-uploaded-avatars/avatars/original/data.jpg"
aws s3 rm "s3://assets.$DOMAIN_NAME/avatars/processed/data.jng"
```

Then we must update our `./bin/avatar/upload` file as well:

```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
DATA_FILE_PATH="$SERVERLESS_PATH/files/data.jpg"

aws s3 cp "$DATA_FILE_PATH" "s3://thejoshdev-uploaded-avatars/avatars/original/data.jpg"
```

With the latest deployment complete, we head over to S3 in the AWS Console and see if our buckets are created. Looks like they are.

![image](https://user-images.githubusercontent.com/119984652/236051725-c7dc17f0-31ab-4a21-a81d-f5dad4b1e23d.png)

We remove all images from our buckets manually through the UI. Next we go back over to our workspace and run our script `./bin/avatar/upload`. We then head back over to S3 and view our `assets` bucket. It appears to have processed the image.

![image](https://user-images.githubusercontent.com/119984652/236053109-bca10966-a7a9-40b2-8c64-43b976347ce3.png)

When we go over to our `thejoshdev-uploaded-avatars` bucket, we see where the original image resides.

![image](https://user-images.githubusercontent.com/119984652/236053325-97e216d6-3b68-40a7-b8af-d72b51080eef.png)

It's decided we'd like to change the folder structure for these buckets, so we update our variables in the `.env` and `.env.example` files:

```.env
THUMBING_S3_FOLDER_INPUT=""
THUMBING_S3_FOLDER_OUTPUT="avatars"
```

We again empty the contents of our S3 buckets through the AWS console. Then we again `cdk deploy`. This fails, giving us an error about not specifying a prefix in the variables we passed above.

![image](https://user-images.githubusercontent.com/119984652/236054605-7b06fd2d-8ef4-438f-ba7a-2fbb34b0da6a.png)

To circumvent this, we comment out the `prefix` from our `createS3NotifyToLambda` function in our `thumbing-serverless-cdk-stack.ts` file. 

```ts
  createS3NotifyToLambda(prefix: string, lambda: lambda.IFunction, bucket: s3.IBucket): void {
    const destination = new s3n.LambdaDestination(lambda);
    bucket.addEventNotification(
      s3.EventType.OBJECT_CREATED_PUT,
      destination//,
      //{prefix: prefix} // folder to contain the original images
    )
  }
```

We again `cdk deploy`. We again edit the folders being created by editing our `./bin/avatar/upload` script.

```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
DATA_FILE_PATH="$SERVERLESS_PATH/files/data.jpg"

aws s3 cp "$DATA_FILE_PATH" "s3://thejoshdev-uploaded-avatars/data.jpg"
```

We execute the script: `./bin/avatar/upload` then check our buckets through S3 again. 

![image](https://user-images.githubusercontent.com/119984652/236056156-3078ff77-7b19-48d1-9f57-72a5697327e3.png)

Our image uploaded as it was suppose to. Now that we've worked out uploading to our S3 buckets, we must work on implementation. Moving back to our workspace, we begin on this by making sure we're logged into ECR first. 

```sh
./bin/ecr/login
```

Next we do a Docker Compose Up. Then, `./bin/db/setup`, `./bin/ddb/schema-load`, and `./bin/ddb/seed` to provide some data to our web app. We access our web app, then login and head over the the Profile page to gather an idea of what we're looking at. We want to return some user activity on the Profile page. Over in our workspace, we create a new query named `backend-flask/db/sql/users/show.sql`. 

```sql
SELECT
  users.uuid,
  users.handle,
  users.display_name,
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
    SELECT
      activities.uuid,
      users.display_name,
      users.handle,
      activities.message,
      activities.created_at,
      activities.expires_at
    FROM public.activities  
    WHERE 
      activities.user_uuid = users.uuid
    ORDER BY activities.created_at DESC
    LIMIT 40    
  ) array_row) as activities
FROM public.users
WHERE
  users.handle = %(handle)s    
```

We begin removing our mock data from our code. We start with `./backend-flask/services/user_activities.py`. 

```py
class UserActivities:
  def run(user_handle):
    try:
      model = {
        'errors': None,
        'data': None
      }

      if user_handle == None or len(user_handle) < 1:
        model['errors'] = ['blank_user_handle']
      else:
        sql = db.template('users','show')
        results = db.query_array_json(sql)
        model['data'] = results
      finally:
      return model
```

With the help of ChatGPT, I've broken down what we're doing above.

We start with a dictionary named "model" with two keys: "errors" and "data", both initially set to None. 

```py
    try:
      model = {
        'errors': None,
        'data': None
      }
```

It checks if the "user_handle" parameter is None or has a length less than 1. If either condition is true, it sets the "errors" key in the "model" dictionary to a list containing the string 'blank_user_handle'.

```py
      if user_handle == None or len(user_handle) < 1:
        model['errors'] = ['blank_user_handle']
```

Otherwise, it retrieves a SQL query from the database object called "db" using the "template" method. The query is expected to retrieve user activities from our database table `users` using the template we just created, `show`. 

```py
      else:
        sql = db.template('users','show')
```

The query is executed using the "query_array_json" method of the "db" object, which retrieves the query results as a JSON array.

```py
        results = db.query_array_json(sql)
```

The query results are assigned to the "data" key in the "model" dictionary. Finally, the "model" dictionary is returned, which contains either the query results or an error message if the "user_handle" parameter was None or had a length less than 1.

```py
        model['data'] = results
      finally:
        return model      
```

We do another Docker compose up, then view the front end of our app. We not returning data. Since we did a `docker compose up` from our terminal, we can see what's wrong there.

![image](https://user-images.githubusercontent.com/119984652/236067378-c977dc24-eb94-4177-90ea-b942d37cddb2.png)

Andrew believes that's because we're actually returning an object, not an array. We update that in our `else` statement.

```py
      else:
        sql = db.template('users','show')
        results = db.query_object_json(sql)
        model['data'] = results
```

We refresh our web app, but there's no change in the error. We can see our query from the terminal:

![image](https://user-images.githubusercontent.com/119984652/236068553-c225e960-cfc0-44f3-a94c-c4db6bf1503f.png)

Nothing is passing along, and Andrew mentions nothing is matching as well. Since nothing is passing along, we comment out our `try`, update our indentation, and add a couple of `print`'s to see what is returning and where.

![image](https://user-images.githubusercontent.com/119984652/236069326-316877f9-8f95-4648-8094-225777fc5da6.png)

We refresh our web app and immediately get an error stating `NameError: name 'db' is not defined`.  That's because we need to import it.

```py
from lib.db import db
```

After a few more syntax cleanups, we are now returning data in our Profile page, but our UI isn't built to implement it just yet. We move over to our `frontend-react-js/src/pages/UserFeedPage.js` file. Andrew explains we're returning the data and we have to `setActivities`, but now it's being set differently. We update our `loadData` function.

```js
  const loadData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/${title}`
      const res = await fetch(backend_url, {
        method: "GET"
      });
      let resJson = await res.json();
      if (res.status === 200) {
        setActivities(resJson.activities)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  };
```

If the response status is 200, the `setActivities` function is called with the `activities` property of the retrieved JSON data as its argument. This updates the component state with the retrieved data. If the response status is not 200, the error response is logged to the console.

We've already set activities. We also have to set the profile, so we create another `const`. 

```js
const [profile, setProfile] = React.useState([]); 
```

Then we call `setActivities` to return the data of the profile.

```js
      if (res.status === 200) {
        setActivities(resJson.profile)
        setActivities(resJson.activities)
```

Andrew explains our data structure doesn't reflect this yet, so we must update our template in `backend-flask/db/sql/users/show.sql`. 

```sql
SELECT
  (SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM (
    SELECT
      users.uuid,
      users.cognito_user_id as cognito_user_uuid,
      users.handle,
      users.display_name,
  ) object_row) as profile,
```

The new subquery uses a `row_to_json` function to convert the select row data into a JSON object. The `COALESCE` function returns an empty JSON object `{}` in case the result of `row_to_json` is NULL. 

We refresh our web app, and we're now returning data. Andrew points out that we can now use this data returned below:

![image](https://user-images.githubusercontent.com/119984652/236334581-71dd17f2-3c74-48fe-9916-05ba259f5268.png)

to populate our Profile page with information. 

Continuing on with integration, we create a new component, `./frontend-react-js/src/components/EditProfileButton.js`. 

```js
import './EditProfileButton.css';

export default function EditProfileButton(props) {
  const pop_profile_form = (event) => {
    event.preventDefault();
    props.setPopped(true);
    return false;
  }

  return (
    <button onClick={pop_profile_form} className='profile-edit-button'>Edit Profile</button>
  );
}
```

We're calling the `pop_profile_form` function, passing it an event object as an argument. 

We add the `EditProfileButton.js` to our `UserFeedPage.js` by importing it. 

```js
import EditProfileButton from '../components/EditProfileButton';
```

We refactor some code by removing it from `./frontend-react-js/src/components/ActivityFeed.js` and placing it into `UserFeedPage.js`. 

![image](https://user-images.githubusercontent.com/119984652/236339390-a6d6964e-4207-403c-8499-d6577fe8f7a0.png)

We then take this refactored code and place it in `HomeFeedPage.js`. 

```js
    <article>
      <DesktopNavigation user={user} active={'home'} setPopped={setPopped} />
      <div className='content'>
        <ActivityForm
          popped={popped}
          setPopped={setPopped} 
          setActivities={setActivities} 
        />
        <ReplyForm 
          activity={replyActivity} 
          popped={poppedReply} 
          setPopped={setPoppedReply} 
          setActivities={setActivities} 
          activities={activities} 
        />
        <div className='activity_feed'>
          <div className='activity_feed_heading'>
            <div className='title'>Home</div>
          </div>         
          <ActivityFeed 
            setReplyActivity={setReplyActivity} 
            setPopped={setPoppedReply} 
            activities={activities} 
          />
        </div>
      </div>
      <DesktopSidebar user={user} />
    </article>
  );
}
```

We also add this to our `NotificationsFeedPage.js` as well. 

```js
        <div className='activity_feed'>
          <div className='activity_feed_heading'>
            <div className='title'>{title}</div>
          </div>        
          <ActivityFeed activities={activities} />
        </div>
```

When we go back to our web app and refresh, it still works. We login, and navigate around various pages to make sure it works. We notice on the Profile page, it's not showing that we're logged in. Andrew explains not all of our conditionals are showing in the Profile page. Back in our workspace, we go to our `HomeFeedPage.js` and add an import for our `checkAuth` and `getAccessToken` functions.

```js
import {checkAuth, getAccessToken} from '../lib/CheckAuth';
```

We add headers to bring in our `access_token`, call the `getAccessToken` function, and add a `const` defining our `access_token`. 

```js
  const loadData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/@${params.handle}`
      await getAccessToken()
      const access_token = localStorage.getItem("access_token")
      const res = await fetch(backend_url, {
        headers: {
          Authorization: `Bearer ${access_token}`
        },
        method: "GET"
      });
```

We then passed `setUser` as an argument for `checkAuth`. 

```js
  React.useEffect(()=>{
    //prevents double call
    if (dataFetchedRef.current) return;
    dataFetchedRef.current = true;

    loadData();
    checkAuth(setUser);
  }, [])
```

When we refresh the Profile page now, it's showing that we're logged in. We begin to talk about how we can implement different structure into the Profile page. We move back over to our `UserFeedPage.js` and make some additions. 

```js
    <article>
      <DesktopNavigation user={user} active={'profile'} setPopped={setPopped} />
      <div className='content'>
        <ActivityForm popped={popped} setActivities={setActivities} />
      
        <div className='activity_feed'>
          <div className='activity_feed_heading'>
            <div className='title'>{profile.display_name}</div>
            <div className='cruds_count'>{profile.cruds_count} Cruds</div>
          </div>
          <ActivityFeed activities={activities} />
        </div>
      </div>
      <DesktopSidebar user={user} />
    </article>
```

We must update our SQL template to return this new data field, `cruds_count`. Back over in `./backend-flask/db/sql/users/show.sql` we update the query.

```sql
SELECT
  (SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM (
    SELECT
      users.uuid,
      users.cognito_user_id as cognito_user_uuid,
      users.handle,
      users.display_name,
      users.bio,
      (
      SELECT 
       count(true)
      FROM public.activities
      WHERE
        activities.user_uuid = users.uuid
       ) as cruds_count
  ) object_row) as profile,
```

We refresh our web app, and now when we inspect the page, we are getting a `ReferenceError: title is not defined` error. 

![image](https://user-images.githubusercontent.com/119984652/236344528-d26b883f-fecb-40fe-9c06-e155ff656376.png)

This is what it's referencing:

![image](https://user-images.githubusercontent.com/119984652/236344588-48b7cbee-a4fd-47b3-9300-852433f654a4.png)

This is correct, we removed this field previously. We move over to `UserFeedPage.js` and update `backend_url`. 

```js
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/@${params.handle}`
```

We refresh our web app again, and our Profile page is not displaying a name or any data. We navigate back to our `UserFeedPage.js` and find that we called `setActivities` twice. Assuming the HTTP response status of the fetch request is equal to 200, the first call to `setActivities` with `resJson.profile` as an argument would set the activities state to the profile value instead of the intended activities data. The second call to `setActivities` with `resJson.activities` would set the activities state to the correct value. We update our code:

```js
      if (res.status === 200) {
        setProfile(resJson.profile)
        setActivities(resJson.activities)
```

Now when we refresh the web app, we are seeing a name displayed on the Profile page. The Crud Count is there as well, its just not easliy visible right now, but we will fix this later.

![image](https://user-images.githubusercontent.com/119984652/236346174-c29db7b7-6e02-449e-865e-9508a5d14bba.png)

Andrew decides now that we're going to break this up into its own component. In `./frontend-react-js-src/components/` we create a new component named `ProfileHeading.js`. 

```js
import './ProfileHeading.css';
import EditProfileButton from '../components/EditProfileButton';

export default function ProfileHeading(props) {

  return (
  <div className='activity_feed_heading profile_heading'>
    <div className='title'>{props.profile.display_name}</div>
    <div className="cruds_count">{props.profile.cruds_count} Cruds</div>
    
    <div className="avatar">
      <img src="https://assets.thejoshdev.com/avatars/data.jpg"></img>
    </div>
      
    <div className="display_name">{props.display_name}</div>
    <div className="handle">{props.handle}</div>
      
    <EditProfileButton setPopped={props.setPopped} />
  </div> 
  );
}
```

In our `UserFeedPage.js` file, we add a `const`: 

```js
  const [poppedProfile, setPoppedProfile] = React.useState([]);
```

Then we add it in our `'activity_feed'`. 

```js
        <div className='activity_feed'>
          <ProfileHeading setPopped={setPoppedProfile} profile={profile} />
```

We again refresh our web app. 

![image](https://user-images.githubusercontent.com/119984652/236349473-5da4b037-ffba-42cd-bfcf-6944883ccc97.png)

`ProfileHeading` is not defined. We need to import it. 

In `UserFeedPage.js`.

```js
import ProfileHeading from '../components/ProfileHeading';
```

We again refresh our web app. The screenshot below is from Andrew's Profile page.

![image](https://user-images.githubusercontent.com/119984652/236350016-1dfb72d2-d88a-472c-8be3-d894d10de2c4.png)

We need to do some styling on this page now. In our `./frontend-react-js/src/components/ProfileHeading.css` file, we begin creating some styling. 

```css
.profile_heading .avatar img {
    width: 140px;
    height: 140px;
    border-radius: 999px;
}
```

We again refresh our web app.

![image](https://user-images.githubusercontent.com/119984652/236350563-9fb53356-61df-4513-ad51-57b62404ca38.png)

We need to add a banner image as well. We search for and find an image online for a banner. We need a way to upload this image as our banner, so we head over to S3 in the AWS console. Then we create a new folder in our `assets` bucket named `banners` and upload our `banner.jpg`. 

In `ProfileHeading.js`, we make several changes.

```js
export default function ProfileHeading(props) {
  const backgroundImage = 'url("https://assets.thejoshdev.com/banners/banner.jpg")';
  const styles = {
    backgroundImage: backgroundImage,
    backgroundSize: 'cover',
    backgroundPosition: 'center',
  };
  return (
    <div className='activity_feed_heading profile_heading'>
    <div className='title'>{props.profile.display_name}</div>
    <div className="cruds_count">{props.profile.cruds_count} Cruds</div>
    <div className="banner" style={styles} >
```

When we refresh our web app now, we have a banner! 

![image](https://user-images.githubusercontent.com/119984652/236351897-ac231596-33ca-481c-aaff-9d5a79cac9a8.png)

We make several changes to the `ProfileHeading.css` file. 

```css
.profile_heading .avatar {
    position: absolute;
    bottom: -74px;
    left: 16px;  
}
.profile_heading .avatar img {
    width: 148px;
    height: 148px;
    border-radius: 999px;
    border: solid 8px var(--fg);
}

.profile_heading .banner {
    position: relative;
    height: 200px;
}
```

Then, we made made changes to the styling of the `EditProfileButton.css`. 

```css
.profile-edit-button {
    border: solid 1px rgba(255,255,255,0.5);
    padding: 12px 20px;
    font-size: 18px;
    background: none;
    border-radius: 999px;
    color: rgba(255,255,255,0.8);
    cursor: pointer;
}

.profile-edit-button:hover {
    background: rgba(255,255,255,0.3);
}
```

We refresh our app and draw our attention to the double entries of the username and the extra line as well. Andrew spots the issue in our `UserFeedPage.js` file and removes the duplicate code, since it now has its own component. Speaking of that component, in `ProfileHeading.js` we begin wrapping our `div`'s. 

```js
    <div className="info">
      <div className='id'>
        <div className="display_name">{props.display_name}</div>
        <div className="handle">@{props.handle}</div>
      </div>
```

We update the styling in `ProfileHeading.css` to reflect the changes.

```css
.profile_heading .banner {
    position: relative;
    height: 200px;
}

.profile_heading .info {
    display: flex;
    flex-direction: row;
    align-items: start;
    padding: 16px;
}

.profile_heading .info .id {
    padding-top: 86px;
    flex-grow: 1;
    color: rgb(255,255,255);
}
```

We refresh our web app again. We find that our username isn't displaying correctly now. 

![image](https://user-images.githubusercontent.com/119984652/236354618-135ef667-2863-4e98-b69e-58728e17598d.png)

The `div`'s we wrapped earlier aren't being called correctly. We fix this in the code: 

From this:

![image](https://user-images.githubusercontent.com/119984652/236354842-6af7082d-40f5-468a-b8d8-9202e4f95a13.png)

To this:

```js

    <div className="info">
      <div className='id'>
        <div className="display_name">{props.profile.display_name}</div>
        <div className="handle">@{props.profile.handle}</div>
      </div>
```

This fixes the issue: 

![image](https://user-images.githubusercontent.com/119984652/236354982-b669fe77-15ae-47b6-9f01-3cc09885c943.png)

We continue editing the styling in `ProfileHeading.css`.

```css
.profile_heading {
    padding-bottom: 0px;
}

.profile_heading .profile-avatar {
    position: absolute;
    bottom: -74px;
    left: 16px;
    width: 148px;
    height: 148px;
    border-radius: 999px;
    border: solid 8px var(--fg);  
}

.profile_heading .banner {
    position: relative;
    height: 200px;
}

.profile_heading .info {
    display: flex;
    flex-direction: row;
    align-items: start;
    padding: 16px;
}

.profile_heading .info .id {
    padding-top: 70px;
    flex-grow: 1;
}

.profile_heading .info .id .display_name {
    font-size: 24px;
    font-weight: bold;
    color: rgb(255,255,255);    
}

.profile_heading .info .id .handle {
    font-size: 16px;
    color: rgba(255,255,255,0.7);
}
```

Then we give the `Edit Profile` button a hover. We edit our `EditProfileButton.css` file. 

```css
.profile-edit-button {
    border: solid 1px rgba(255,255,255,0.5);
    padding: 12px 20px;
    font-size: 18px;
    background: none;
    border-radius: 999px;
    color: rgba(255,255,255,0.8);
    cursor: pointer;
}

.profile-edit-button:hover {
    background: rgba(255,255,255,0.3);
}
```

When we refresh our web app this time, our `Edit Profile` button is visible, readable, and has a hover action. 

![image](https://user-images.githubusercontent.com/119984652/236355595-017a5ece-cc28-4b21-8179-f0a39d79a630.png)

We add more styling to `ProfileHeading.css` to make our Crud Count visible. 

```css
.profile_heading .cruds_count {
    color: rgba(255,255,255,0.7);
}
```

![image](https://user-images.githubusercontent.com/119984652/236355879-836e4989-5501-49ae-9657-1ffd8b83cc2e.png)

At the start of the next instructional video, Andrew explains that he's found a solution to a constant problem we've had since the beginning of bootcamp. Consistantly when we update code and refresh our web app, additional spaces need to be entered for the new code to be pushed to the logs. We go to our `./backend-flask/Dockerfile` and add the following:

```Dockerfile
ENV PYTHONUNBUFFERED=1
```

A little extra insight via ChatGPT:

"The `ENV PYTHONUNBUFFERED=1` statement is used in a Dockerfile to set an environment variable. Specifically, it sets the `PYTHONUNBUFFERED` variable to the value of 1.

In Python, when the standard output (stdout) or standard error (stderr) streams are used, the output may be buffered, meaning that the output is held in a buffer before being written to the console. This can lead to unexpected behavior when running Python scripts in a containerized environment, where logs and output may not appear immediately.

Setting `PYTHONUNBUFFERED` to 1 disables output buffering for Python, which ensures that output is immediately written to the console. This can be useful for logging and debugging purposes."

We make sure we're signed into ECR, then we attempt a Docker compose up. 

![image](https://user-images.githubusercontent.com/119984652/236572220-dcf33d88-d78d-4d74-a6ca-3ac6f4504f6f.png)

This is happening because the script `generate-env` is not running correctly for our backend from our `.gitpod.yml` file. We view the file. While viewing, we add a new section for Docker, so we can be logged into ECR automatically when launching our workspace. 

![image](https://user-images.githubusercontent.com/119984652/236572804-a9b5e79f-bc61-414a-a124-13a223fa3e40.png)

We also remove the `source` from the path to run the `generate-env` script.

```yml
  - name: flask 
    command: |
      "$THEIA_WORKSPACE_ROOT/bin/backend/generate-env"
```

To test this, we commit our changes, then quit and relaunch our workspace. The change failed.

![image](https://user-images.githubusercontent.com/119984652/236573173-23b62b28-4c0e-4075-b314-1835488ccfe4.png)

For the sake of moving onward, for now, we remove the scripts from our `.gitpod.yml` file. We also remove the section for Docker we added above. Instead, we go back to our `/bin/bootstrap` file. Maybe we can get this working correctly for logging into ECR. 

```sh
#! /usr/bin/bash
set -e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="bootstrap"
printf "${CYAN}====== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
BIN_DIR=$(dirname $ABS_PATH)

source "$BIN_DIR/ecr/login"
source "$BIN_DIR/backend/generate-env"
source "$BIN_DIR/frontend/generate-env"
```

When we run the script, it logs us into ECR and generates a `backend-flask.env` and a `frontend-react-js.env` file. We then decide to try and get a script running to do what we originally set out `./bin/bootstrap` to do. We create `./bin/prepare`. 

```sh
#! /usr/bin/bash
set -e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="prepare"
printf "${CYAN}====== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
BIN_PATH=$(dirname $ABS_PATH)
DB_PATH="$BIN_PATH/db"
DDB_PATH="$BIN_PATH/ddb"

source "$DB_PATH/create"
source "$DB_PATH/schema-load"
source "$DB_PATH/seed"
python "$DB_PATH/update_cognito_user_ids"
python "$DDB_PATH/schema-load"
python "$DDB_PATH/seed"
```

We make the file executable, then do a Docker compose up. With our environment running, we check the ports and see the backend is not running. We view the logs of the backend. 

![image](https://user-images.githubusercontent.com/119984652/236574903-2a87c991-8910-4ec9-8c31-c15ef1198460.png)

When we added `ENV PYTHONUNBUFFERED=1` to our Dockerfile earlier, we forgot to remove the `-u` from our Docker `CMD`. We do so now. 

```Dockerfile
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567", "--debug"]
```

We compose down our environment, then compose up again. We check the ports again and everything is now running. We then run our new script `./bin/prepare`. This script does not work, so we manually run the scripts to setup our tables and seed data to our web app locally. With our app now getting data, we login. We navigate over to our Profile page. 

![image](https://user-images.githubusercontent.com/119984652/236577465-e027e749-0c42-40c8-8554-909ec197828a.png)

When we click the `Edit Profile` button, nothing happens right now. We begin implenting some new code. We create a new file named `./frontend-react-js/jsconfig.json`. 

```json
{
    "compilerOptions": {
      "baseUrl": "src"
    },
    "include": ["src"]
  }
```

The `compilerOptions` object contains options that affect how code is compiled into JavaScript. In this case, the option specified is `baseUrl`, which sets the base directory for resolving non-relative module names. Specifically, it sets the base URL for resolving module specifiers in import statements to the `src` directory.

For example, in our `HomeFeedPage.js` file, we can now alter our import statements from this:

![image](https://user-images.githubusercontent.com/119984652/236578762-dfcb52e4-ee70-4b80-b756-dafc6741d6b3.png)

To this:

```js
import DesktopNavigation  from 'components/DesktopNavigation';
import DesktopSidebar     from 'components/DesktopSidebar';
import ActivityFeed from 'components/ActivityFeed';
import ActivityForm from 'components/ActivityForm';
import ReplyForm from 'components/ReplyForm';
import {checkAuth, getAccessToken} from 'lib/CheckAuth';
```

Andrew further explains its powerful due to this fact how we can move our files around anywhere in our directories as the pathing is absolute to the import. 

Moving onward, we create another new component, `./frontend-react-js/src/components/ProfileForm.js`

```js
import './ProfileForm.css';
import React from "react";
import process from 'process';
import {getAccessToken} from 'lib/CheckAuth';

export default function ProfileForm(props) {
  const [bio, setBio] = React.useState(0);
  const [displayName, setDisplayName] = React.useState(0);

  React.useEffect(()=>{
    console.log('useEffects',props)
    setBio(props.profile.bio);
    setDisplayName(props.profile.display_name);
  }, [props.profile])

  const onsubmit = async (event) => {
    event.preventDefault();
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/profile/update`
      await getAccessToken()
      const access_token = localStorage.getItem("access_token")
      const res = await fetch(backend_url, {
        method: "POST",
        headers: {
          'Authorization': `Bearer ${access_token}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          bio: bio,
          display_name: displayName
        }),
      });
      let data = await res.json();
      if (res.status === 200) {
        setBio(null)
        setDisplayName(null)
        props.setPopped(false)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  }

  const bio_onchange = (event) => {
    setBio(event.target.value);
  }

  const display_name_onchange = (event) => {
    setDisplayName(event.target.value);
  }

  const close = (event)=> {
    console.log('close',event.target)
    if (event.target.classList.contains("profile_popup")) {
      props.setPopped(false)
    }
  }

  if (props.popped === true) {
    return (
      <div className="popup_form_wrap profile_popup" onClick={close}>
        <form 
          className='profile_form popup_form'
          onSubmit={onsubmit}
        >
          <div class="popup_heading">
            <div class="popup_title">Edit Profile</div>
            <div className='submit'>
              <button type='submit'>Save</button>
            </div>
          </div>
          <div className="popup_content">
            <div className="field display_name">
              <label>Display Name</label>
              <input
                type="text"
                placeholder="Display Name"
                value={displayName}
                onChange={display_name_onchange} 
              />
            </div>
            <div className="field bio">
              <label>Bio</label>
              <textarea
                placeholder="Bio"
                value={bio}
                onChange={bio_onchange} 
              />
            </div>
          </div>
        </form>
      </div>
    );
  }
}
```

"The component takes in props as a parameter, which includes `props.popped`, a boolean indicating whether the popup is currently shown or not, and `props.profile`, an object containing the current user profile information. We're using React hooks such as `useState` and `useEffect` to manage state and perform side effects. `useState` is used to manage the state of `bio` and `displayName`, which hold the user's bio and display name respectively. `useEffect` is used to update the `bio` and `displayName` states whenever the `props.profile` object changes. The component also defines several functions that handle events such as form submission and input change. When the form is submitted, it sends a POST request to the backend API to update the user's profile information. When the input fields are changed, it updates the corresponding states. Finally, the component returns the popup form if `props.popped` is true, and null otherwise." - thank you ChatGPT.

We then get to work on the `frontend-react-js/src/components/ProfileForm.css` file. 

```css
form.profile_form input[type='text'],
form.profile_form textarea {
  font-family: Arial, Helvetica, sans-serif;
  font-size: 16px;
  border-radius: 4px;
  border: none;
  outline: none;
  display: block;
  outline: none;
  resize: none;
  width: 100%;
  padding: 16px;
  border: solid 1px var(--field-border);
  background: var(--field-bg);
  color: #fff;
}

.profile_popup .popup_content {
  padding: 16px;
}

form.profile_form .field.display_name {
  margin-bottom: 24px;
}

form.profile_form label {
  color: rgba(255,255,255,0.8);
  padding-bottom: 4px;
  display: block;
}

form.profile_form textarea {
  height: 140px;
}

form.profile_form input[type='text']:hover,
form.profile_form textarea:focus {
  border: solid 1px var(--field-border-focus)
}

.profile_popup button[type='submit'] {
  font-weight: 800;
  outline: none;
  border: none;
  border-radius: 4px;
  padding: 10px 20px;
  font-size: 16px;
  background: rgba(149,0,255,1);
  color: #fff;
}
```

With the styling completed, we now move over to our `UserFeedPage.js` file and import the `ProfileForm` then return it. 

```js
import ProfileForm from 'components/ProfileForm'; 

  return (
    <article>
      <DesktopNavigation user={user} active={'profile'} setPopped={setPopped} />
      <div className='content'>
        <ActivityForm popped={popped} setActivities={setActivities} />
        <ProfileForm 
          profile={profile}
          popped={poppedProfile} 
          setPopped={setPoppedProfile} 
        />

        <div className='activity_feed'>
          <ProfileHeading setPopped={setPoppedProfile} profile={profile} />
          <ActivityFeed activities={activities} />
        </div>
      </div>
      <DesktopSidebar user={user} />
    </article>
  );
}
```

When we refresh our web app and click `Edit Profile` it's getting a bit better.

![image](https://user-images.githubusercontent.com/119984652/236581772-517e21c5-eef3-4e40-a047-efe10a254392.png)

We refactor some code from `./frontend-react-js/src/components/ReplyForm.css` by removing a portion, then refactoring it into a new component called `Popup.css`.

```css
.popup_form_wrap {
  z-index: 100;
  position: fixed;
  height: 100%;
  width: 100%;
  top: 0;
  left: 0;
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  align-items: center;
  padding-top: 48px;
  background: rgba(255,255,255,0.1)
}

.popup_form {
  background: #000;
  box-shadow: 0px 0px 6px rgba(190, 9, 190, 0.6);
  border-radius: 16px;
  width: 600px;
}

.popup_form .popup_heading {
  display: flex;
  flex-direction: row;
  border-bottom: solid 1px rgba(255,255,255,0.4);
  padding: 16px;
}

.popup_form .popup_heading .popup_title{
  flex-grow: 1;
  color: rgb(255,255,255);
  font-size: 18px;

}
```

We need to import this. Andrew says since this is a global component, we will import it into `frontend-react-js/src/app.js`.

```js
import './components/Popup.css';
```

We refresh our web app and take a look.

![image](https://user-images.githubusercontent.com/119984652/236582644-f3a62a2a-33a8-4a16-9d06-da07466e319e.png)

Andrew notes that if we click outside of the Profile form, the form goes away. This is by design. Andrew shows us `frontend-react-js/src/components/ProfileForm.js`. 

![image](https://user-images.githubusercontent.com/119984652/236624465-8184cfe6-eea2-41f0-b061-c14d0e8cc058.png)


The `close` function in the code is an event listener function that is called when the user clicks on the `div` element with `className` of `popup_form_wrap profile_popup`. The function checks if the clicked element has a `classList` that contains `profile_popup` and, if so, it calls `props.setPopped(false)` to update the popped state to false and close the popup. 

We now must add an endpoint for the Profile so it will save. We navigate over to our `./backend-flask/app.py` file and implement it.

```py
@app.route("/api/profile/update", methods=['POST','OPTIONS'])
@cross_origin()
def data_update_profile():
  bio          = request.json.get('bio',None)
  display_name = request.json.get('display_name',None)
  access_token = extract_access_token(request.headers)
  try:
    claims = cognito_jwt_token.verify(access_token)
    cognito_user_id = claims['sub']
    model = UpdateProfile.run(
      cognito_user_id=cognito_user_id,
      bio=bio,
      display_name=display_name
    )
    if model['errors'] is not None:
      return model['errors'], 422
    else:
      return model['data'], 200
  except TokenVerifyError as e:
    # unauthenicatied request
    app.logger.debug(e)
    return {}, 401
```

More ChatGPT insight: 
"The function first retrieves the `bio` and `display_name` parameters from the JSON data in the request body, and extracts the `access_token` from the request headers using the `extract_access_token` function. The try block attempts to verify the access token using the `cognito_jwt_token.verify` function, which returns a dictionary containing the token's claims if successful. The `cognito_user_id` is extracted from the claims using the `sub` key.

The `UpdateProfile.run` method is then called with the `cognito_user_id`, `bio`, and `display_name` parameters to update the user's profile data. The model variable contains the result of the `UpdateProfile.run` method call.

If `model['errors']` is not None, indicating that there were errors during the update operation, the function returns the errors and a status code of 422. Otherwise, the function returns the data and a status code of 200 (OK).

If the access token cannot be verified due to a `TokenVerifyError`, the function returns an empty dictionary and a status code of 401 (Unauthorized)."

We also add an import statement for the service.

```py
from services.update_profile import *
```

Then, we create a new service for this in `./backend-flask/services` named `update_profile.py`. 

```py
from lib.db import db

class UpdateProfile:
  def run(cognito_user_id,bio,display_name):
    model = {
      'errors': None,
      'data': None
    }

    if display_name == None or len(display_name) < 1:
      model['errors'] = ['display_name_blank']

    if model['errors']:
      model['data'] = {
        'bio': bio,
        'display_name': display_name
      }
    else:
      handle = UpdateProfile.update_profile(bio,display_name,cognito_user_id)
      data = UpdateProfile.query_users_short(handle)
      model['data'] = data
    return model

  def update_profile(bio,display_name,cognito_user_id):
    if bio == None:    
      bio = ''

    sql = db.template('users','update')
    handle = db.query_commit(sql,{
      'cognito_user_id': cognito_user_id,
      'bio': bio,
      'display_name': display_name
    })
  def query_users_short(handle):
    sql = db.template('users','short')
    data = db.query_select_object(sql,{
      'handle': handle
    })
    return data
```

The run method takes `cognito_user_id`, `bio`, and `display_name` parameters, and returns a dictionary containing errors and data keys. The method first sets the errors and data values to None.

If display_name is None or has a length less than 1, the errors list is set to `['display_name_blank']`. Andrew said we will handle errors near the end of the bootcamp. Otherwise, the `update_profile` method is called with the `bio`, `display_name`, and `cognito_user_id` parameters, and the `query_users_short` method is called with the handle value returned from the `update_profile` method to retrieve the updated user data.

If there are no errors, the data value is set to the updated user data. The model dictionary is then returned with the errors and data keys.

The `update_profile` method takes `bio`, `display_name`, and `cognito_user_id` parameters and updates the user data in the database with the specified values. The method first sets the bio value to an empty string if it is None, and then executes a query to update the user data in the database.

The `query_users_short` method takes a handle parameter and executes an SQL query to retrieve the user data associated with the specified handle. The method then returns the user data as a dictionary.

Now we must add the query that's going to update the user's profile. We make a new file in `./backend-flask/db/users` named `update.sql`.

```sql
UPDATE public.users 
SET 
  bio = %(bio)s,
  display_name= %(display_name)s
WHERE 
  users.cognito_user_id = %(cognito_user_id)s
RETURNING handle;
```

We're returning the `handle` after updating the `bio` and `display_name` fields in the `public.users` table for the user with a `cognito_user_id` that matches the value provided by the `%(cognito_user_id)s` parameter. The values provided by the `%(bio)s` and `%(display_name)s` parameters sets the `bio` and `display_name` fields respectively. 

Andrew explained that in our `update_profile.py` file, we are using `./backend-flask/db/users/short.sql` which takes a handle, which is why we're returning `handle` in `./backend-flask/db/users/update.sql`.

![image](https://user-images.githubusercontent.com/119984652/236628587-313a0184-e0f6-4578-b895-8dfa10f2d34d.png)

Currently, there's no `bio` field added to our database. This code will fail if ran. We need to add it to our database. Andrew said we could've just added a query to insert it, but at some point we were needing migrations functionality added, so we begin discussing SQL migrations.

What are SQL migrations? Let's let ChatGPT explain:
"SQL migrations are a way of managing changes to the database schema over time, typically as part of a software development process. A migration is a script that describes a change to the database schema, such as adding or modifying a table, column, or index. The migration script is executed by a tool or framework that manages the database schema, which applies the changes to the database.

SQL migrations allow developers to evolve the database schema over time in a controlled and repeatable manner. They also help to manage the complexity of database changes by providing a history of changes that can be reviewed, rolled back, or applied incrementally. In addition, migrations enable collaboration between developers working on the same project by providing a standardized way of managing database changes."

Andrew shows us an example of a SQL migration library built on SQLAlchemy, but said that for the purposes of our learning, we're going to setup one of our own. We create a new folder in our `./bin/` directory named `generate`, then inside the new folder, a new Python script named `migration`.

```py
#!/usr/bin/env python3
import time
import os
import sys

if len(sys.argv) == 2:
  name = sys.argv[1]
else:
  print("pass a filename: eg. ./bin/generate/migration add_bio_column")
  exit(0)

timestamp = str(time.time()).replace(".","")

filename = f"{timestamp}_{name}.py"

# convert undername name to title case e.g. add_bio_column -> AddBioColumn
klass = name.replace('_', ' ').title().replace(' ','')

file_content = f"""
from lib.db import db
class {klass}Migration:
  def migrate_sql():
    data = \"\"\"
    \"\"\"
    return data
  def rollback_sql():
    data = \"\"\"
    \"\"\"
    return data
  def migrate():
    db.query_commit({klass}Migration.migrate_sql(),{{
    }})
  def rollback():
    db.query_commit({klass}Migration.rollback_sql(),{{
    }})
migration = AddBioColumnMigration
"""
# remove leading and trailing new lines
file_content = file_content.lstrip('\n').rstrip('\n')

current_path = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations',filename))
print(file_path)

with open(file_path, 'w') as f:
  f.write(file_content)
```

Andrew breaks this down. First we have a name:

```py
if len(sys.argv) == 2:
  name = sys.argv[1]
else:
  print("pass a filename: eg. ./bin/generate/migration hello")
  exit(0)
```

We generate a unique timestamp based on the current time in seconds, to create a unique filename for the migration file:

```py
timestamp = str(time.time()).replace(".","")

```

The script then constructs the filename by concatenating the timestamp and the desired migration name:

```sh
filename = f"{timestamp}_{name}.py"
```

Then we generate out a Python Migration file. 

```py
file_content = f"""
from lib.db import db
class {klass}Migration:
  def migrate_sql():
    data = \"\"\"
    \"\"\"
    return data
  def rollback_sql():
    data = \"\"\"
    \"\"\"
    return data
  def migrate():
    db.query_commit({klass}Migration.migrate_sql(),{{
    }})
  def rollback():
    db.query_commit({klass}Migration.rollback_sql(),{{
    }})
migration = AddBioColumnMigration
"""
```

We then write the contents of the migration file by getting the current directory of the script, contructing a path to the `migrations` directory, which we haven't created yet. 

```py
current_path = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations',filename))
```

Next, it then opens a file object at this path and writes the contents of the `file_content` variable to it.

```py
with open(file_path, 'w') as f:
  f.write(file_content)
```

We now have to create the directory our script is writing to. We navigate over to `backend-flask/db/` and create a new folder named `migrations`. Within the directory, we create a `.keep` file, since the directory is currently empty, but we want to KEEP the directory around regardless. Then, we make our new script executable. After this, we test the script.

```sh
./bin/generate/migration add_bio_column
```

![image](https://user-images.githubusercontent.com/119984652/236630218-9f64688f-b969-4b10-a9b7-43dac3566106.png)

You can see we now generated the Python file below:

![image](https://user-images.githubusercontent.com/119984652/236630271-2a8b56cf-2b82-4803-852d-8f45bca09982.png)

We view the generated migration file:

![image](https://user-images.githubusercontent.com/119984652/236630348-bb24fff4-9464-43c0-ab9e-96acdcd27e26.png)

Andrew explains the idea is we can generate the file, then we populate it. 

```py
from lib.db import db

class AddBioColumnMigration:
  def migrate_sql():
    data = """
    ALTER TABLE public.users ADD COLUMN bio text;
    """
    return data
  def rollback_sql():
    data = """
    ALTER TABLE public.users DROP COLUMN;
    """
    return data
    
  def migrate():
    this.query_commit(AddBioColumnMigration.migrate_sql(),{
    })
    
  def rollback():
    this.query_commit(AddBioColumnMigration.rollback_sql(),{
    })
    
migration = AddBioColumnMigration
```

With what we've populated in the migration file, the function `migrate_sql` will return a string that performs the SQL query to add the new column `bio` to our database.  `rollback_sql` function will return a string that performs a SQL query to drop the `bio` column instead, hence "rollback". Andrew explains in Ruby and other languages, these functions are called an "up" and a "down" instead of "migrate" and "rollback" respectively. We're naming them as they are because you "migrate forward" to add the column and "rollback" to revert the changes and drop the column.

We need a way to trigger these migration files. For this, we will create a couple of new scripts. We head to our `./bin/db` directory and create two new scripts within this folder: `migrate` and `rollback`. Before even implementing code to these scripts, we make them executable so we don't forget. Then, we implement `./bin/db/migrate`.

```py
#!/usr/bin/env python3

import os
import sys
import glob
import re
import time
import importlib

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
from lib.db import db

def get_last_successful_run():
  sql = """
  SELECT
      coalesce(
      (SELECT last_successful_run
      FROM public.schema_information
      LIMIT 1),
      '0') as last_succesful_run
  """
  return int(db.query_value(sql,{},verbose=False))

def set_last_successful_run(value):
  sql = """
  UPDATE schema_information
  SET last_successful_run = %(last_successful_run)s
  """
  db.query_commit(sql,{'last_successful_run': value})
  return value

last_successful_run = get_last_successful_run()

migrations_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations'))
sys.path.append(migrations_path)
migration_files = glob.glob(f"{migrations_path}/*")


for migration_file in migration_files:
  filename = os.path.basename(migration_file)
  module_name = os.path.splitext(filename)[0]
  match = re.match(r'^\d+', filename)
  if match:
    file_time = int(match.group())
    if last_successful_run <= file_time:
      mod = importlib.import_module(module_name)
      mod.migration.migrate()
      print('running migration: ',module_name)
      timestamp = str(time.time()).replace(".","")
      last_successful_run = set_last_successful_run(timestamp)
```

In this script, we are importing the necessary modules, including the `db` module from our backend `lib`. Then, we're setting the `current_path` and `parent_path` env vars based on the location of the script and our backend directory. 

```py
import os
import sys
import glob
import re
import time
import importlib

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
from lib.db import db
```

Our `get_last_successful_run` function is querying the `schema_information` table to get the timestamp of the last successful migration. If there's been no successful migration recorded, it's returning a value of 0. 

```py
def get_last_successful_run():
  sql = """
  SELECT
      coalesce(
      (SELECT last_successful_run
      FROM public.schema_information
      LIMIT 1),
      '0') as last_succesful_run
  """
  return int(db.query_value(sql,{},verbose=False))
```

The `set_last_successful_run` function updates the `schema_information` table with the provided timestamp and returns the same value.

The script then retrieves the last successful migration timestamp using `get_last_successful_run`, and sets the `migrations_path` env var to the migrations directory in the backend's `db` directory. It uses `glob` to retrieve a list of all migration files in the directory, and iterates over them in order of filename as a list or array.

```py
def set_last_successful_run(value):
  sql = """
  UPDATE schema_information
  SET last_successful_run = %(last_successful_run)s
  """
  db.query_commit(sql,{'last_successful_run': value})
  return value

last_successful_run = get_last_successful_run()

migrations_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations'))
sys.path.append(migrations_path)
migration_files = glob.glob(f"{migrations_path}/*")
```

For each migration file, the script extracts the filename and module name, and extracts the timestamp from the filename using a regular expression. If the timestamp is greater than or equal to the last successful migration timestamp, the script imports the module and calls its `migrate` method to perform the migration. It then updates the `schema_information` table with the current timestamp using `set_last_successful_run`.

```py
for migration_file in migration_files:
  filename = os.path.basename(migration_file)
  module_name = os.path.splitext(filename)[0]
  match = re.match(r'^\d+', filename)
  if match:
    file_time = int(match.group())
    if last_successful_run <= file_time:
      mod = importlib.import_module(module_name)
      mod.migration.migrate()
      print('running migration: ',module_name)
      timestamp = str(time.time()).replace(".","")
      last_successful_run = set_last_successful_run(timestamp)
```

For this to run correctly, we must implement the `schema_information` table into our `./backend-flask/db/schema.sql` file. We add a query to create the table.

```sql
CREATE TABLE IF NOT EXISTS public.schema_information (
  last_successful_run text
);
```

Andrew explains this query is different than others because we're not dropping this table if it exists, we're creating the table if it doesn't exist since it's storing useful information for migrations. Since our code is already expecting the table to be created, from our terminal we will manually add it. But first, we must connect to our database, so we'll use our `connect` script to do so.

```sh
./bin/db/connect
```

Now that we're connected to our database, we create the table. 

![image](https://user-images.githubusercontent.com/119984652/236636902-b29468a5-c91a-41e6-a826-8eb3ab58368f.png)

We next run the query for our `get_last_successful_run` function manually, just so we can see what the value is returned.

![image](https://user-images.githubusercontent.com/119984652/236637047-da87ddc3-f62c-43a7-aa57-d3839c510121.png)

Since we have not run the migration yet, the value is 0. Andrew explains the way `coalesce` works within our function.

![image](https://user-images.githubusercontent.com/119984652/236637085-43bd1a2a-48b9-412c-8f86-79e444d8e436.png)

Since we always want to return a default value, and there's current no value since we've never ran a migration, we want to return back a number, or empty value. In the snippet above,  if there is no record, `coalesce` returns back a NULL value. Since we can't return a number, we're returning a string value of `0` instead. If this does not make sense, just remember: the query retrieves the value of the `last_successful_run` column from the `schema_information` table, or the string '0' if the column does not exist or is NULL.

We now move onto the other script we were working on, `./bin/db/rollback`.

```py
#!/usr/bin/env python3

import os
import sys
import glob
import re
import time
import importlib

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
from lib.db import db

def get_last_successful_run():
  sql = """
  SELECT
      coalesce(
      (SELECT last_successful_run
      FROM public.schema_information
      LIMIT 1),
      '0') as last_succesful_run
  """
  return int(db.query_value(sql,{},verbose=False))

def set_last_successful_run(value):
  sql = """
  UPDATE schema_information
  SET last_successful_run = %(last_succesful_run)s
  """
  db.query_commit(sql,{'last_successful_run': value})
  return value

last_successful_run = get_last_successful_run()

migrations_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations'))
sys.path.append(migrations_path)
migration_files = glob.glob(f"{migrations_path}/*")


last_migration_file = None
for migration_file in migration_files:
  if last_migration_file == None:
    filename = os.path.basename(migration_file)
    module_name = os.path.splitext(filename)[0]
    match = re.match(r'^\d+', filename)
    if match:
      file_time = int(match.group())
      if last_successful_run > file_time:
        last_migration_file = module_name
print(last_migration_file)
```

This script is similar to `migrate` as we're using `get_last_successful_run` and `set_last_successful_run`, adding the migration file path and iterating through it, but the key difference is, we're just checking for the last migration. 

```py
last_migration_file = None
for migration_file in migration_files:
  if last_migration_file == None:
    filename = os.path.basename(migration_file)
    module_name = os.path.splitext(filename)[0]
    match = re.match(r'^\d+', filename)
    if match:
      file_time = int(match.group())
      if last_successful_run > file_time:
        last_migration_file = module_name
print(last_migration_file)
```

`last_migration_file` is initially set to None. On each migration file, if `last_migration_file` is still None, the filename and module name is extracted, then it's checked to see if the timestamp is smaller than the last successful migration file's timestamp. If this condition is true, the `module_name` is assigned to `last_migration_file`. The loop will stop after the first migration file that is older than the last successful run is found, and `last_migration_file` will contain the name of the last migration that was run successfully. Then we print out the value of the `last_migration_file`. 

We attempt to run the `migrate` script.

```sh
./bin/db/migrate
```

![image](https://user-images.githubusercontent.com/119984652/236637966-78438963-2973-4a34-a71c-0b49abd45e60.png)

Andrew explains we're receiving this error because he didn't want our queries to print out on our return statement `return int(db.query_value(sql,{},verbose=False))`. To fix this, we must update `./backend-flask/lib/db.py`. 

```py
  def query_commit(self,sql,params={},verbose=True):
    if verbose:
      self.print_sql('commit with returning',sql,params)
```

```py
  def query_array_json(self,sql,params={},verbose=True):
    if verbose: 
      self.print_sql('array',sql,params)
```

```py
  def query_object_json(self,sql,params={},verbose=True):
    if verbose: 
      self.print_sql('json',sql,params)
      self.print_params(params)
```

```py
  def query_value(self,sql,params={},verbose=True):
    if verbose: 
      self.print_sql('value',sql,params)
```

We again attempt to run our script. This time, we receive a different error from the terminal:

![image](https://user-images.githubusercontent.com/119984652/236638421-aa1c4b6c-c5d2-406f-bd7e-813fdc3fe1e0.png)

We must navigate back over to our `migration.py` file to fix. We update the file from this:

![image](https://user-images.githubusercontent.com/119984652/236638494-ad567a87-d8cc-4abe-bc22-aa2fb630f0e2.png)

To this: 

![image](https://user-images.githubusercontent.com/119984652/236638478-7279e702-8f18-466e-9a9f-a6be3dec27c2.png)

Then we make the same changes to the queries in our migration file in the `./backend-flask/db/migrations` directory itself. 

![image](https://user-images.githubusercontent.com/119984652/236638680-adf78767-9a23-45cb-9f69-5670fa96aa66.png)

We again run our script: `./bin/db/migrate`. 

![image](https://user-images.githubusercontent.com/119984652/236638739-3ef4df0c-957c-4a0d-ba05-99142036a713.png)

You can see from the image above that we're setting the `last_successful_run`. Since we know that's working, we add the additional flag we added above to our `migrate` script to remove the query from printing out. 

```py
db.query_commit(sql,{'last_successful_run': value},verbose=False)
```

Since `migrate` is now working, we need to see of `rollback` will. We run our script: `./bin/db/rollback`. It returns None, but it should be returning the value of `last_migration_file`, which we know ran successfully with `migrate`. We add a few print lines to our code in `rollback` to see what's being returned, then run the script again.

![image](https://user-images.githubusercontent.com/119984652/236639020-d005dc5a-1607-44a4-b68c-b83c638f0dee.png)

![image](https://user-images.githubusercontent.com/119984652/236639032-6c622915-b425-4e2a-8249-42c360530636.png)

We can see that `last_successful_run` is returning None. We return to the terminal where we're connected to our database and repeat our query for `get_last_successful_run`:

![image](https://user-images.githubusercontent.com/119984652/236639113-ddf27c7e-515e-4cdc-8089-d24d900ecade.png)

We try to manually set `last_successful_run` in the `schema_information` table by running our query manually for `set_last_successful_run`:

```sql
UPDATE schema_information SET last_successful_run ="1";
```

Then we again repeat the `get_last_successful_run` query to see what's returned:

![image](https://user-images.githubusercontent.com/119984652/236639297-0ac26e7f-90ab-49e0-bca1-0e076b77cf73.png)

Andrew said this is because we're trying to update the table instead of inserting into it. Since `last_successful_run` should never be None or NULL value, we have to update our queries. In `migrate`, we update the query for `get_last_successful_run`. 

```py
def get_last_successful_run():
  sql = """
    SELECT last_successful_run
    FROM public.schema_information
    LIMIT 1
  """
  return int(db.query_value(sql,{},verbose=False))
```

We update `rollback` with the updated query as well. Then, we move over to `./backend-flask/db/schema.sql`as we must insert into the `schema_information` table.

```sql
INSERT INTO public.schema_information (last_successful_run) 
VALUES ("0")
```

Andrew further explains that we only want to do this once. So there must be a condition where the record is only created if the record doesn't exist. We add this:

```sql
INSERT INTO public.schema_information (last_successful_run) 
VALUES ("0")
WHERE (SELECT count(true) FROM public.schema_information) = 0
```

We attempt to manually insert into our database from terminal where we're connected, but it doesn't work. Our `WHERE` clause is invalid. We modify the query:

```sql
INSERT INTO public.schema_information (last_successful_run) 
SELECT "0"
WHERE (SELECT count(true) FROM public.schema_information) = 0
```

![image](https://user-images.githubusercontent.com/119984652/236640383-d971fdde-c9b5-4817-becf-6e40907d1928.png)

After some review, Andrew provides a solution. We will add another field to our `schema_information` table. This will allow us to insert into the database but it will be dependent upon the value of `id`. We also add the `UNIQUE` constraint to the `id` field to ensure that nothing else can appear with the same value.

```sql
CREATE TABLE IF NOT EXISTS public.schema_information (
  id integer UNIQUE,
  last_successful_run text
);
INSERT INTO public.schema_information (id,last_successful_run) 
VALUES (1,'0')
ON CONFLICT (id) DO NOTHING;
```

The query now inserts a single row with `id` set to 1 and `last_successful_run` set to '0'. The `ON CONFLICT` clause specifies that if a row with `id` of 1 already exists, then the insert should do nothing.

We manually drop our table `schema_information`. Then we manually run our first query above:

```sql
CREATE TABLE IF NOT EXISTS public.schema_information (
  id integer UNIQUE,
  last_successful_run text
);
```

Then our second:

![image](https://user-images.githubusercontent.com/119984652/236641144-c36d45a2-d4d1-458f-b717-741615738ed9.png)

It completed successfully. We check to be sure.

```sql
SELECT * FROM schema_information;
```

![image](https://user-images.githubusercontent.com/119984652/236641176-6da6ad82-482c-42f1-94fe-d0f61933cd38.png)

Then to test our `ON CONFLICT` clause by running the query again to make sure it won't insert. 

![image](https://user-images.githubusercontent.com/119984652/236641201-fcbe1a31-5f97-4e19-b669-cddbac999df6.png)

Before we can test our `rollback` script again, we must manually run the query from our generated migration file, since it didn't run correctly the first time.

![image](https://user-images.githubusercontent.com/119984652/236641276-a83830bc-8744-4e73-a8b4-a2e4c9087a2d.png)

```sql
ALTER TABLE public.users DROP COLUMN bio;
```
The query completes successfully. Now, we can attempt our migration again. 

```sh
./bin/db/migrate
```

![image](https://user-images.githubusercontent.com/119984652/236641364-2f236547-af25-4404-82e0-747c857ef0d0.png)

We again query our database to make sure the `migrate` script worked correctly.

![image](https://user-images.githubusercontent.com/119984652/236641413-9aa43f6d-c8b8-4339-a26d-7c137b6f0e5b.png)

We again test `rollback`.

```sh
./bin/db/rollback
```

This time it completes successfully.

![image](https://user-images.githubusercontent.com/119984652/236641460-fb6fbbbe-9d4a-4aaa-a776-9412b4bdbe87.png)

We now must alter our `rollback` script as we only want it to run once. For this, we grab code from our `migrate` script and refactor it into our `rollback` script. 

```py
last_migration_file = None
for migration_file in migration_files:
  if last_migration_file == None:
    filename = os.path.basename(migration_file)
    module_name = os.path.splitext(filename)[0]
    match = re.match(r'^\d+', filename)
    if match:
      file_time = int(match.group())
      if last_successful_run > file_time:
        last_migration_file = module_name
        mod = importlib.import_module(module_name)
        print('=== rolling back: ',module_name)      
        mod.migration.rollback()
        set_last_successful_run(file_time)
```

We also update our query for `set_last_successful_run` in `rollback` and `migrate` to be more explicit by adding a `WHERE` clause. 

```py
def set_last_successful_run(value):
  sql = """
  UPDATE schema_information
  SET last_successful_run = %(last_successful_run)s
  WHERE id = 1
  """
  db.query_commit(sql,{'last_successful_run': value})
  return value
```

We want to test this, so we again run our `migrate` script.

```sh
./bin/db/migrate
```

We refresh our web app, then navigate to the Profile page and click `Edit Profile`. When we attempt to update the Bio field then save, nothing happens. We access the backend logs to see if we're getting any errors, which it turns out, we are:

![image](https://user-images.githubusercontent.com/119984652/236642002-25b97450-6752-411f-a645-de3e5a1c0a08.png)

Andrew has a good idea what the problem is. We move over to our `backend-flask/services/update_profile.py` file and take a look at the `query_users_short` function. 

![image](https://user-images.githubusercontent.com/119984652/236642085-95795a83-10b2-4708-93e3-da57d6bde05a.png)

It's no longer `query_select_object` just `query_object`. We update the code:

![image](https://user-images.githubusercontent.com/119984652/236642148-6ef43057-4e1f-4c70-8bea-6128239468f6.png)

We refresh the web app, then view our backend logs again:

![image](https://user-images.githubusercontent.com/119984652/236642191-6ecff5a8-b055-4967-b233-21c9b1385ae7.png)

We navigate to `./backend-flask/lib/db.py` to check the function there and make sure we're naming it correctly here. 

![image](https://user-images.githubusercontent.com/119984652/236642305-adfda2dd-86b7-44fe-8207-c85c8483bdcd.png)

Since we're wanting to return JSON here, we need to update `update_profile.py` to use `query_object_json` instead.

![image](https://user-images.githubusercontent.com/119984652/236642352-9cb0916c-4583-4977-9e59-dc3e1942cd4e.png)

Another app refresh, and another error is returned from the backend logs.

![image](https://user-images.githubusercontent.com/119984652/236646024-a80246ba-a236-4fc5-96bb-bdbf4a67b8a4.png)

We navigate to our `./backend-flask/app.py` file and review. It's a problem with our try. We're not assigning `model` :

```py
@app.route("/api/profile/update", methods=['POST','OPTIONS'])
@cross_origin()
def data_update_profile():
  bio          = request.json.get('bio',None)
  display_name = request.json.get('display_name',None)
  access_token = extract_access_token(request.headers)
  try:
    claims = cognito_jwt_token.verify(access_token)
    cognito_user_id = claims['sub']
    UpdateProfile.run(
      cognito_user_id=cognito_user_id,
      bio=bio,
      display_name=display_name
    )
    if model['errors'] is not None:
      return model['errors'], 422
    else:
      return model['data'], 200
  except TokenVerifyError as e:
    # unauthenicatied request
    app.logger.debug(e)
    return {}, 401
```

We make the change to assign it:

```py
  try:
    claims = cognito_jwt_token.verify(access_token)
    cognito_user_id = claims['sub']
    model = UpdateProfile.run(
      cognito_user_id=cognito_user_id,
      bio=bio,
      display_name=display_name
    )
    if model['errors'] is not None:
      return model['errors'], 422
```

Now when we make a change to our Profile from the web app and click Save, our edit menu goes away. The change isn't propagated right away, but requires a refresh of the page, then the changes are reflected in the Profile. Now that this is working, we need to render out our Bio that we added to the Profile. We head over to `./frontend-react-js/src/components/ProfileHeading.js`. We want to add this as a separate `div` beneath our `Edit Profile` button.

```js
  return (
    <div className='activity_feed_heading profile_heading'>
    <div className='title'>{props.profile.display_name}</div>
    <div className="cruds_count">{props.profile.cruds_count} Cruds</div>
    <div className="banner" style={styles} >
      <ProfileAvatar id={props.profile.cognito_user_uuid} />
    </div>
    <div className="info">
      <div className='id'>
        <div className="display_name">{props.profile.display_name}</div>
        <div className="handle">@{props.profile.handle}</div>
      </div>
      <EditProfileButton setPopped={props.setPopped} />
    </div>
    <div className="bio">{props.profile.bio}</div>

  </div> 
  );
}
```

Next we move over to the `ProfileHeading.css` file to work on the styling for the Bio section:

```css
.profile_heading .bio {
    padding: 16px;
    color: rgba(255,255,255,0.7);
}
```

Then, we have to make sure `bio` is included in data returned, so we navigate to our template query in `./backend-flask/db/sql/users/show.sql` and add it.

```sql
SELECT
  (SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM (
    SELECT
      users.uuid,
      users.cognito_user_id as cognito_user_uuid,
      users.handle,
      users.display_name,
      users.bio,
      (
```

Now when we refresh our web app, we have a bio field added to the Profile page! 

![image](https://user-images.githubusercontent.com/119984652/236646594-90c034fb-4d74-42f5-a60d-3f0fb04a568f.png)

Moving on, we need to implement the uploading of our avatars to our web app. To get started on this, we need to install the AWS SDK for S3. From the terminal, we install it. 

```sh
npm i @aws-sdk/client-s3 --save
```

Next, we start a new function to `ProfileForm.js`.  

```js
const s3upload = async (event)=> {

}
```

Then, we have to add an `onClick` event for this function.

```js
<div className="upload" onClick={s3upload}>
  Upload Avatar
</div>
```

We're going to upload to our bucket through use of an API endpoint that will trigger a Lambda, so now we move over to the AWS Console and launch API Gateway. From here, we are prompted as to what type of API we would like to build.

![image](https://user-images.githubusercontent.com/119984652/236677542-59ddc0a5-ffa7-44c2-b3e4-4868ea4b6e79.png)

We select HTTP API, then we're prompted to configure our integrations. We choose a Lambda integration, but we do not have our Lambda function created yet. So we open an additional tab, and navigate to Lambda through the AWS console. Andrew mentions we can make this function in any language we want. Andrew's affinity for Ruby shines through, and we select Ruby as the Runtime for our newly named function, `CruddurAvatarUpload`. 

![image](https://user-images.githubusercontent.com/119984652/236677913-d1d8eddd-2c4a-4e20-8019-88b3ec0f7f72.png)

On permissions, we leave it with the option "Create a new role with basic Lambda permissions", as we'll create our own role. We leave all Advanced Settings unchecked.

![image](https://user-images.githubusercontent.com/119984652/236678031-b3bbdd41-e4f7-4021-91a4-8f2b4cca8257.png)

Then, we create our function. We want to generate out a presigned URL. The reason for this is a client will make a request to the API Gateway we're setting up. It requests a presigned URL for uploading an object, in our case, an image to S3. API Gateway will invoke the Lambda function, generating the presigned URL using the AWS SDK. Our Lambda function will return the presigned URL to the API, in turn returning it to the client as well. The client then uses the presigned URL to upload the image to our S3 bucket. 

To have a place to work on our function, we create a new folder in our `./aws/lambdas` directory named `cruddur-upload-avatar`, then a new file within named `function.rb`. We first add code to initialize the client.

```ruby
require 'aws-sdk-s3'

client = Aws::S3::Client.new()
```

Andrew explains we will next generate out a Gem file. A Gem file, or Gemfile, is a configuration file used in Ruby to specify the required Ruby gems (or libraries) for a Ruby project. 

Further clarification per Google:
"When you start a new Ruby project or work on an existing one, you may need to use external libraries or frameworks to add extra functionality to your project. RubyGems is a package manager that allows you to easily install and manage these libraries. A Gemfile is a text file that lists the required gems for a Ruby project, and specifies their version requirements."

To generate out the Gemfile, we cd over to the correct directory in our terminal. `/workspace/aws-bootcamp-cruddur-2023/aws/lambdas/cruddur-upload-avatar/`. Next, we run a command to generate the Gemfile.

```sh
bundle init
```

![image](https://user-images.githubusercontent.com/119984652/236678688-8eba830a-44cc-4812-92c4-ed7bb0e7ba00.png)

The Gemfile is generated.

![image](https://user-images.githubusercontent.com/119984652/236678729-b482f3f4-fc7b-4314-a238-751c8bf610b3.png)

We access the Gemfile created. Then, we add a library for "aws-sdk-s3".

```gemfile
# frozen_string_literal: true

source "https://rubygems.org"

# gem "rails"
gem "aws-sdk-s3"
```

Next, we install the library from terminal.

```sh
bundle install
```

This installs from terminal.

![image](https://user-images.githubusercontent.com/119984652/236678892-ed79312f-4fe6-446e-ac7b-2ca586bb7069.png)

We can also see there's now a `Gemfile.lock` file in our directory. This file lists all of the versions of all the gems (or libraries) that are installed in the Ruby project (directory), along with their dependencies.

![image](https://user-images.githubusercontent.com/119984652/236678908-d4e97f8a-20af-4d4a-a752-d355ee23b7c8.png)

Next we must add code to return a presigned URL for upload to our function. While researching this, we find that we don't actually need to initialize the client. 

```ruby
require 'aws-sdk-s3'

s3 = Aws::S3::Resource.new
bucket_name = ENV["UPLOADS_BUCKET_NAME"]
object_key = "mock.jpg"

obj = s3.bucket(bucket_name).object(object_key)
url = obj.presigned_url(:put, expires_in: 3600)
puts url
```

We're going to be passing some env vars to our function that need to be stored in our workspace. We're generating some of the env vars in our `.env.example` file from our `./thumbing-serverless-cdk` directory, particularly `UPLOADS_BUCKET_NAME`, but they need to be accessible from the entire workspace, so we pass the env vars through our terminal in our workspace.  

```sh
export  UPLOADS_BUCKET_NAME="thejoshdev-uploaded-avatars"
gp env UPLOADS_BUCKET_NAME="thejoshdev-uploaded-avatars"
```

We run our function from the terminal to see what is returning for `url`. 

```sh
bundle exec ruby function.rb
```

We receive a runtime error. We're missing an XML pareser:

![image](https://user-images.githubusercontent.com/119984652/236680040-2194a53c-4da2-4d36-9a57-ee5e32a5dbcf.png)

We go back to our `Gemfile` and edit the libraries to include Ox, which is an XML parser.

```gemfile
# frozen_string_literal: true

source "https://rubygems.org"

# gem "rails"
gem "aws-sdk-s3"
gem "ox"
```

We install the new library from our `Gemfile`. 

```sh
bundle install
```

The new library is installing.

![image](https://user-images.githubusercontent.com/119984652/236680187-766056cd-269c-4edf-9bb5-400e17573dc7.png)

We again try running our `function.rb` file.

```sh
bundle exec ruby function.rb
```

This time it runs and returns a presigned URL via the terminal.

![image](https://user-images.githubusercontent.com/119984652/236680299-46aa4a9e-ac38-4f75-887f-0981ca3f902e.png)

Andrew then shows us how to use an API client through our workspace in GitPod. We install a new client from the UI called Thunder Client. 

![image](https://user-images.githubusercontent.com/119984652/236680433-5f329f42-439c-44bc-b994-b638126f02ff.png)

If we use the presigned URL that was generated and insert it into Thunder Client, it prepopulates our Query Parameters. 

![image](https://user-images.githubusercontent.com/119984652/236692668-1897bbfb-3348-4433-b22f-37611ff67cf5.png)

We need to see if we can upload to our S3 bucket using the API. We upload an image downloaded from the internet to our workspace in our `./aws/lambdas/cruddur-upload-avatar` directory. 

![image](https://user-images.githubusercontent.com/119984652/236692794-d6cd9cd3-a85d-47e1-932e-0a14b5978ec5.png)

Back in Thunder Client, we go to Body > Binary > Choose File > then select our `lore.jpg` file. We click Send, and receive a `403 Forbidden` error. 

![image](https://user-images.githubusercontent.com/119984652/236692866-39eda895-9ee9-445d-8ab7-ae212b1d0748.png)

With the error provided, it gives some insight: "Check your key and signing method." We go back to our `function.rb` file and view the `expires_in` parameter of our presigned url. 

![image](https://user-images.githubusercontent.com/119984652/236692993-a31298aa-20c6-48c0-a5fc-d85c96317227.png)

It's currently set to 3600 seconds or 1 hour. This should be sufficient time for the `lore.jpg` file to upload to our S3 bucket. We change the method of the request from Thunder Client to a `PUT`. Then, we try to Send again. 

![image](https://user-images.githubusercontent.com/119984652/236693121-64b583a7-40a9-4dab-9d46-d8a5dcf322e7.png)

This time it succeeds. We go back to S3 in AWS and check our `joshdev-uploaded-avatars` bucket. 

![image](https://user-images.githubusercontent.com/119984652/236693171-e49b4042-de04-4550-aa20-e9fc71c815b0.png)

The file uploaded successfully. After testing this and seeing it work, we delete the `mock.jpg` file from our bucket. Now we need to package our `function.rb` file into a Ruby Lambda. 

```ruby
require 'aws-sdk-s3'
require 'json'

def handler(event:, context:)
  puts event
  s3 = Aws::S3::Resource.new
  bucket_name = ENV["UPLOADS_BUCKET_NAME"]
  object_key = 'mock.jpg'
  
  obj = s3.bucket(bucket_name).object(object_key)
  url = obj.presigned_url(:put, expires_in: 3600)
  url # this is the data that will be returned
  body = {url: url}.to_json
  { statusCode: 200, body: body }
end  
```

The added code added a Lambda function `handler` that takes two parameters: `event` and `context`. I learned from ChatGPT that `event` is a hash containing information about the event that triggered the Lambda function, and `context` is an object containing information about the current execution environment. The pre-signed URL is converted to a JSON string using the `to_json` method and assigned to the `body` variable.

Finally, an HTTP response is returned with a `statusCode` of 200 (indicating success) and a `body` containing the pre-signed URL as a JSON string.

We copy our code from `function.rb` and go back over to our Lambda we created. We select Code, then paste our code into the field. We click Deploy to deploy the code to our Lambda, then select Configuration > Permissions to check our Lambda's permissions. We select the execution role, which transfers us over to IAM in the AWS console. We create an inline policy named `PresignedUrlAvatarPolicy` granting our Lambda `s3:PutObject` permissions. This will give the Lambda permissions to upload images to our S3 bucket. 

![image](https://user-images.githubusercontent.com/119984652/236694456-0da5110f-22d6-4c60-a863-2dcfd0b07dd0.png)

Just so we have the code, we copy the JSON of the policy and create a new file in our workspace under the `./aws/policies` directory named `s3-upload-avatar-presigned-url-policy.json`. Then we paste the code into the file. We move back to our Lambda in AWS, as we need further configuration. We pass env vars in the Lambda function, so we need to store these for the Lambda. From the Configuration tab, we select Environment Variables > Edit. We add the env var for our `UPLOADS_BUCKET_NAME`.

![image](https://user-images.githubusercontent.com/119984652/236694692-f33c4940-3b54-480c-96b4-eeff5d50dffb.png)

We should be fully configured to test our Lambda. Prior to this though, we adjust the `expires_in` paramter of the presigned URL that's being generated to a shorter time period of five minutes. We make the update under the Code tab in our Lambda as well. 

```ruby
    url = obj.presigned_url(:put, expires_in: 60 * 5)
```

We test our Lambda from AWS and receive an error. 

![image](https://user-images.githubusercontent.com/119984652/236694881-e42f0280-cc24-4f46-9a89-34179edb2e55.png)

Andrew explains we did not set the handler from AWS. We go back to the Code tab and scroll down. Under Runtime Settings, we update Handler...

...from this:

![image](https://user-images.githubusercontent.com/119984652/236694969-c32f7c00-d550-4e8e-804c-03d8e6edaf3c.png)

To this:

![image](https://user-images.githubusercontent.com/119984652/236695014-8aca6f18-cd37-49dc-a4d0-63a041d72944.png)

We test again and receive a new error.

![image](https://user-images.githubusercontent.com/119984652/236695038-89465afc-f314-4cf3-9aa8-0e4c0345f668.png)

Our file is named incorrectly in Lambda. From the Code tab, we rename the file to `function.rb`. We test again. This time, it succeeds.

![image](https://user-images.githubusercontent.com/119984652/236695105-d7986cee-801e-4fb5-af26-d87200980bcf.png)

The result returned was our presigned URL. This should work as intended. Andrew mentions we still will need an authorization Lambda before it calls this. For this, we decide to use `aws-jwt-verify`. We create a new directory and file in `./aws/lambdas/lambda-authorizer/index.js`. 

```js
"use strict";
const { CognitoJwtVerifier } = require("aws-jwt-verify");
//const { assertStringEquals } = require("aws-jwt-verify/assert");

const jwtVerifier = CognitoJwtVerifier.create({
  userPoolId: process.env.USER_POOL_ID,
  tokenUse: "access",
  clientId: process.env.CLIENT_ID//,
  //customJwtCheck: ({ payload }) => {
  //  assertStringEquals("e-mail", payload["email"], process.env.USER_EMAIL);
  //},
});

exports.handler = async (event) => {
  console.log("request:", JSON.stringify(event, undefined, 2));

  const jwt = event.headers.authorization;
  try {
    const payload = await jwtVerifier.verify(jwt);
    console.log("Access allowed. JWT payload:", payload);
  } catch (err) {
    console.error("Access forbidden:", err);
    return {
      isAuthorized: false,
    };
  }
  return {
    isAuthorized: true,
  };
};
```

This will need to get installed into the `package.json` so we cd over to the `./aws/lambdas/lambda-authorizer` directory, then run `npm install aws-jwt-verify --save`. This creates a `package-lock.json`and `package.json`files, as well as a `node_modules` folder. These files and folder store our dependencies for `aws-jwt-verify`.

![image](https://user-images.githubusercontent.com/119984652/236696860-ad2dd182-606d-4799-9535-76498c5db392.png)

We select all of the files in the `lambda-authorizer` directory and download them locally. We zip the contents of the files to a `.zip` folder named `lambda-authorizer`.  We navigate back over to Lambda in AWS. Here, we create a new Lambda named `CruddurApiGatewayLambdaAuthorizer`.

![image](https://user-images.githubusercontent.com/119984652/236697132-37314c19-50d4-4309-9872-2d71f46573fe.png)

We then upload the `.zip` folder we created locally. 

![image](https://user-images.githubusercontent.com/119984652/236697198-11f5f3fe-3ba9-4008-b702-327645ef9c28.png)

We shift gears back over to our API Gateway now. We move forward creating the API with a Lambda integration, now we can select our `CruddurAvatarUpload` Lambda that we created and give it an API name of `api.thejoshdev.com`. Next we configure the routes. We at first select a `GET` method, with the resource path being `/avatars/key_upload` and an integration target of `CruddurAvatarUpload`. Stages is set to `$default`. With the API created, we select Authorization. Then we create a new authorizer named `CruddurJWTAuthorizer` using our `lambda-authorizer` we created earlier. We then attach the authorizer to our route. 

![image](https://user-images.githubusercontent.com/119984652/236697696-0ce56f22-b37d-4278-a45a-86150dc2bde5.png)

We select Stages from the left hand menu, then copy our Invoke URL to test the API gateway. We open a new browser tab and paste the Invoke URL, adding the path `/avatars/key_upload` which is the route we defined for our API gateway. Since we're not passing authorization headers here, this shouldn't work, and it doesn't. 

![image](https://user-images.githubusercontent.com/119984652/236697878-1ea9bfca-6035-4355-b53f-841c89204fd0.png)

To see if the Lambda was triggered, we navigate over to the authorization Lambda we created, select the Monitor tab, then we viewed the CloudWatch logs. The log group didn't exist, so that means the Lambda did not trigger. Just as previously thought, it's likely due to the fact that we're not passing those authorization headers. Since we are passing those headers in our `./frontend-react-js/src/components/ProfileForm.js` file, we navigate over there and begin implementing an HTTP request for our API by continuing back to work on the `s3upload` function we were working on earlier. We add the invoke URL from our API gateway as well. 

```js
const s3upload = async (event)=> {
  try {
    const backend_url = "https://clbx5fa2yb.execute-api-us-east-1.amazonaws.com/avatars/key_upload"
    await getAccessToken()
    const access_token = localStorage.getItem("access_token")
    const res = await fetch(backend_url, {
      method: "POST",
      headers: {
        'Authorization': 'Bearer ${access_token}',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }})
```

While working on this code, we got to the method and Andrew thought we should change the method of our route in our API gateway, so we open it up in the AWS console again. We then edit the route and change it to a `POST`. We then go back to our code.

We open up `ProfileForm.css` and add some styling just to see what we're doing while working through the new `s3upload` function. 

![image](https://user-images.githubusercontent.com/119984652/236698997-4b908789-888c-4076-ad29-e6d91bd5f71e.png)

We move back over to our web app and refresh. We again select `Edit Profile`. 

![image](https://user-images.githubusercontent.com/119984652/236699037-89f6b54e-bf23-49a8-9d56-89c6c9c0800f.png)

When we click into it, we view the web app through Inspect in the browser. We're getting a `failed to fetch` error.

![image](https://user-images.githubusercontent.com/119984652/236699106-583df9d7-7392-4e5d-aa2f-f068f12f5378.png)

When we view `key_uploads`, the route to our API gateway through Inspect, it's returning a 404 error. 

![image](https://user-images.githubusercontent.com/119984652/236699155-6279d127-738a-4463-a4d1-84af1b48c824.png)

As it so happens, this is a CORS issue. The `OPTIONS` request method that we're receiving a 404 error on is primarily used in combination with CORS. When a client makes a cross-origin request, the browser sends an `OPTIONS` preflight request to the server to determine if the requested resource is allowed to be accessed from the client's domain. The server responds with the appropriate CORS headers that allow or deny the request. In our case, it's denying it. 

We head back over to our API gateway in AWS and select CORS from the left hand menu. We then configure CORS setting the `Access-Control-Allow-Origin` to `*.gitpod.io` and setting our `Access-Control-Allow-Methods` to `POST` and `OPTIONS`. 

![image](https://user-images.githubusercontent.com/119984652/236699736-58559842-8ab6-4971-8262-72cd28d7d114.png)

One more refresh of our web app, then clicking on Upload Avatar. We're still getting a CORS error. 

![image](https://user-images.githubusercontent.com/119984652/236699979-c48385cb-52c0-4275-b787-0ed6ffd77a49.png)

There is however, one route that returns a 204 for `OPTIONS`. 

![image](https://user-images.githubusercontent.com/119984652/236699840-368ea7b4-3b5a-4d2c-b319-b84bf6e9ac60.png)

We further configure CORS in API Gateway, for testing purposes opening CORS up entirely.

![image](https://user-images.githubusercontent.com/119984652/236700260-c84e5fc1-bc39-4c28-959b-f17e080f60ea.png)

We test the web app again. Still having CORS errors.

![image](https://user-images.githubusercontent.com/119984652/236700312-ad3f2d42-0889-460d-b15c-cf7dfdf1ae31.png)

For now, we're putting this on pause. Instead, we decide to go back to implenting our presigned URL. In our `./frontend-react-js/src/components/ProfileForm.js` file, we have the function named `s3upload`. This function contains our `backend_url`. We rename the function to `s3uploadkey`. We then update the `div` where it's implemented.

![image](https://user-images.githubusercontent.com/119984652/236700763-51d2e770-e007-47a6-9a76-2a9cbb3ee6a6.png)

Then, we copy the `div` and pass another function named `s3upload`. 

![image](https://user-images.githubusercontent.com/119984652/236700805-9044c5ad-ee89-4686-9352-baa2617d5d0d.png)

One function will be the upload itself, the other the actual presigned URL. We copy the function code for `s3uploadkey` and paste into `ProfileForm.js` naming the function `s3upload`. Next, before we edit the code, we must remove the `div` we created for `s3upload` previously and add an `input type` instead.

![image](https://user-images.githubusercontent.com/119984652/236700983-4d81b3f1-d1b0-42a7-b9c3-31f2d5b6b573.png)

We go back to the code for `s3upload` and begin editing it. 

```js
  const s3upload = async (event)=> {
    const file = event.target.files[0]
    filename = file.name
    size = file.size
    type = file.type
    const preview_image_url = URL.createObjectURL(file)
    console.log(filename,size,type)
    try {
      console.log('s3upload')
      const backend_url = ""
      const res = await fetch (backend_url, {
        method: "POST",
        headers: {
          'Accept': 'appplication/json',
          'Content-Type': 'application/json'
      }})
```

We want the function to pass binary data to fetch, so we ask ChatGPT for some generated code. We further verify to pass a file in js. ChatGPT replies back letting us know "to pass a file to the `fetch` function in Javascript, you can use the `FormData` object to create a form with a file input and submit it as a `POST` request." We implement the suggestion.

![image](https://user-images.githubusercontent.com/119984652/236701485-6c6ba0e0-88b8-497c-a398-487920b8d8ed.png)

Next, we update our `function.rb` file to include a `puts` at the end of the function so we can view when this is ran. We don't want to commit this to our Lambda in AWS, as we're just doing this for troubleshooting purposes at the moment. 

![image](https://user-images.githubusercontent.com/119984652/236701797-86cbee11-270e-491f-91e0-866c226c0628.png)

We select another terminal tab and cd over to our `aws/lambdas/cruddur-upload-avatar` directory, then run our `function.rb`. 

```sh
bundle exec ruby function.rb
```

In Andrew's example below, you can see it returned a presigned URL.

![image](https://user-images.githubusercontent.com/119984652/236701877-69a46bed-f0ef-4c9d-8c33-59e724806df7.png)

We copy the presigned URL, then paste it as the value for `backend_url` back over in `ProfileForm.js` in our `s3upload` function.

![image](https://user-images.githubusercontent.com/119984652/236701951-864c1ed5-2000-4187-b6f9-5cd229d3570a.png)

We go back to our web app, refresh the page, select the `Edit Profile` button, and we now have a `Choose File` button to upload.

![image](https://user-images.githubusercontent.com/119984652/236702015-6367672e-6c6f-488d-a689-028abd04f495.png)

We select our file to upload, then view Inspect in our browser.

![image](https://user-images.githubusercontent.com/119984652/236702098-fe4b884f-6211-4b88-ad61-473f18852cb1.png)

We need to add `const` to several of our variables in `ProfileForm.js` on `s3upload`.

```js
  const s3upload = async (event)=> {
    const file = event.target.files[0]
    const filename = file.name
    const size = file.size
    const type = file.type
    const preview_image_url = URL.createObjectURL(file)
    console.log(filename,size,type)
```

We refresh our web app once again, attempt to upload once again, and this time, we come back with a CORS error.

![image](https://user-images.githubusercontent.com/119984652/236702290-75d67f16-b3fd-4947-8f6f-617c88e34d29.png)

We also got a 403 on preflight, so just to rule that out, we generate out a new presigned URL by running `function.rb` again from the terminal.

```sh
bundle exec ruby function.rb
```

We again copy/paste the URL into `s3upload` as the value passed to `backend_url`. We again refresh our web app, then attempt an upload. This time, we return the same results from Inspect in our browser. More CORS errors. Andrew begins to think we might not need the `FormData` object. We remove this from our code, and also update the fetch method on `body` to `file`. 

![image](https://user-images.githubusercontent.com/119984652/236702615-782abb82-8580-4748-a635-10efcdba554e.png)

When we refresh our web app and attempt the upload again, we again receive the CORS error and the 403 on preflight. Back in `ProfileForm.js`, we update `s3upload` further by changing the method to `PUT`, removing the `'Accept'` from the headers being passed, and updated the `'Content-Type'` header to `type`.

![image](https://user-images.githubusercontent.com/119984652/236702763-8802808c-5400-4b69-8850-a6e32a540633.png)

Refreshed our web app, then attempted another upload avatar: more CORS errors! We're now getting CORS errors from both the frontend and backend of our application. 

In our next instructional video, Andrew opens letting us know that a fellow bootcamper has solved the scripting issues we were having previously within our `.gitpod.yml` file. 

![image](https://user-images.githubusercontent.com/119984652/236703052-2b21f877-7b82-4493-b6d2-8522ef0f8ce8.png)

We move over to `.gitpod.yml` and update the file:

```yml
tasks:
  - name: aws-cli
    env:
      AWS_CLI_AUTO_PROMPT: on-partial
    before: |
      cd /workspace
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install
      cd $THEIA_WORKSPACE_ROOT
      bash bin/ecr/login
```

There was another fix found for our `generate-env` scripts found. 

![image](https://user-images.githubusercontent.com/119984652/236703195-a56a85eb-63da-48b2-ba15-fdce394a7a84.png)

We also update `.gitpod.yml` with this change as well:

```yml
  - name: flask 
    command: |
      ruby "$THEIA_WORKSPACE_ROOT/bin/backend/generate-env"
      cd backend-flask
      pip install -r requirements.txt
  - name: react-js
    command: |
      ruby "$THEIA_WORKSPACE_ROOT/bin/frontend/generate-env"
      cd frontend-react-js
      npm i         
```

Moving on, we now have a fix for our CORS issue with our API Gateway. We go back over to API Gateway in the AWS console. An additional route is needed to be added.

![image](https://user-images.githubusercontent.com/119984652/236703368-51e459d3-ba60-4989-8fe3-37b3b5e7b557.png)

There is no authorizer attached to this route. CORS also needs to be updated.

![image](https://user-images.githubusercontent.com/119984652/236703465-2280f4fa-c0c6-4f79-a009-6ed034cebfeb.png)

Now we must pass our headers as part of our Lambda. We navigate through AWS over to Lambda and access our upload Lambda.

```ruby
require 'aws-sdk-s3'
require 'json'

def handler(event:, context:)
  puts event
  s3 = Aws::S3::Resource.new
  bucket_name = ENV["UPLOADS_BUCKET_NAME"]
  object_key = 'mock.jpg'
  
  obj = s3.bucket(bucket_name).object(object_key)
  url = obj.presigned_url(:put, expires_in: 60 * 5)
  url # this is the data that will be returned
  body = {url: url}.to_json
  {
    headers: {
      "Access-Control-Allow-Headers": "*, Authorization",
      "Access-Control-Allow-Origin": "https://3000-jhargett1-awsbootcampcru-em6b96761ns.ws-us93.gitpod.io",
      "Access-Control-Allow-Methods": "OPTIONS,GET,POST"
    },
    statusCode: 200,
    body: body
    
  }
end 
```

The `"Access-Control-Allow-Origin"` header will have to be updated every time we spin up our environment through our workspace. We deploy the changes to our code in our Lambda. We then refresh our web app. Andrew is starting from a new environment, so he's having to run our various scripts to get data running to our web app. During this, he forgets to run the migrations script we created and has the great idea to add it to our `./bin/db/setup` script as well. 

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
python "$DB_PATH/migrate"
```

From our web app, we again test the upload avatar.

![image](https://user-images.githubusercontent.com/119984652/236704192-daaf28b7-0192-4128-bb05-7ec093cf14fc.png)

This is occurring because we're not passing along the origin in our headers. Back in `s3uploadkey` in our `ProfileForm.js` file, we add the origin to our headers.

```js
      const res = await fetch(gateway_url, {
        method: "POST",
        body: JSON.stringify(json),
        headers: {
          'Origin': "https://3000-jhargett1-awsbootcampcru-em6b96761ns.ws-us93.gitpod.io",
          'Authorization': `Bearer ${access_token}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
```

We refresh our web app and try the upload avatar again. This time we get 200 statuses.

![image](https://user-images.githubusercontent.com/119984652/236704870-ea882c45-3eab-43e0-81e0-a6db64ca09cc.png)

We also return the presigned URL. We move back to our code and pass when successful.

![image](https://user-images.githubusercontent.com/119984652/236704983-80d9aab8-5124-4e0a-962b-8e98846c8a1a.png)

From there, we edit `s3upload` to pass that value.

![image](https://user-images.githubusercontent.com/119984652/236705099-9446d5fc-e26f-4f43-b2a4-f3607cd761ba.png)

We then want to return that data.

![image](https://user-images.githubusercontent.com/119984652/236705172-4332cbf6-e672-4429-9787-3420d08b12e5.png)

Then, in `s3upload`, we assign `presignedurl` to wait for `s3uploadkey` to complete.

![image](https://user-images.githubusercontent.com/119984652/236705316-a5eb9cb5-9b10-4938-9801-ccc949696e5b.png)

We know that we're passing the presigned URL, so we remove the `div` for this from `ProfileForm.js`. We again refresh our web app, then try to upload an image. We're still getting the CORS errors.

![image](https://user-images.githubusercontent.com/119984652/236705441-0be91eb0-a0f4-4298-8f7f-824fe8d5fa04.png)

We're getting closer to resolving the issue. We move now to variable for `backend_url` and how we're passing the `Origin` header in our `s3uploadkey` function in `ProfileForm.js`. Currently the values are hard coded. To solve this, we will need to get our custom domain going for API Gateway. We already have `api.thejoshdev.com` for our load balancer, but we need to use it for API Gateway as well.  Andrew is thinking we'll be able to point our load balancer to our API Gateway for any requests needed. Certain prefixes can go to API Gateway, the rest can go to AWS Fargate. We setup a custom domain for API Gateway. 

![image](https://user-images.githubusercontent.com/119984652/236705805-7049db5f-97a6-4fc7-a961-d555ed162b20.png)

At the start of another instructional video, we may now know the solution to why we were having problems with uploading to the S3 bucket. We head back over to our `thejoshdev-uploaded-avatars` S3 bucket in AWS. Under the Permissions tab, we write a CORS configuration in JSON format.

![image](https://user-images.githubusercontent.com/119984652/236943462-8cd44e42-7535-4815-8a1d-9785cf371711.png)

We also copy this to our workspace so we have it just in case. We make a new directory and file for it at `./aws/s3/cors.json`. 

```json
[
    {
        "AllowedHeaders": [
            "*"
        ],
        "AllowedMethods": [
            "PUT"
        ],
        "AllowedOrigins": [
            "https://*.gitpod.io"
        ],
        "ExposeHeaders": [
            "x-amz-server-side-encryption",
            "x-amz-request-id",
            "x-amz-id-2"
        ],
        "MaxAgeSeconds": 3000
    }
]
```

Back in our workspace, we start up a fresh environment with a Docker compose up. We then run our various scripts to get data to our web app. We run into a snag during running of our scripts, as we have to make a slight edit to `./bin/db/setup` as the path command for running `./bin/db/migrate` was incorrect. Since it's a Python script, we must alter the command.

```sh
python "$DB_PATH/migrate"
```

That fixes the script and we continue on. With our web app receiving data and the environment launched, we login to our web app. We head back over to the Profile page, then click the `Edit Profile` button. Before attempting to upload, we go back over to our workspace and access our `ProfileForm.js` file. Our values passed for the `Origin` header may have updated since we reloaded a new environment. Since we don't want to have to update this every time we start a new environment, we would like to update this automatically. We search through our `ProfileForm.js` and find our `onsubmit` function. It's passing `backend_url` with a value of `'${process.env.REACT_APP_BACKEND_URL}/api/profile/update'`. 

![image](https://user-images.githubusercontent.com/119984652/236948499-57603234-2f9c-4b89-aa23-670eafaf9c1e.png)

The env var being passed, `REACT_APP_BACKEND_URL`, we head over to our `frontend-react-js/.env.example` file and note the value passed for it for later. 

```.env
REACT_APP_BACKEND_URL="https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
```

Back over in `ProfileForm.js`, Andrew thinks twice of passing the `Origin` header in our `s3uploadkey` function, and instead opts to try setting the mode of our fetch request to CORS. 

![image](https://user-images.githubusercontent.com/119984652/236950506-a9366553-705f-4a6d-8da0-298bc93900a4.png)

We head back over to our web app and refresh the page, the test uploading an image. From Inspect in our browser, we're now getting a 404 error undefined on our `PUT`. 

![image](https://user-images.githubusercontent.com/119984652/236951005-74f2a8bb-72a8-46ae-b601-77a55d39529e.png)

We revert the change in `ProfileForm.js` and pass the `Origin` header once again. But we update it as we were doing previously, using the new env var we added.

```js
        headers: {
          'Origin': process.env.REACT_APP_FRONTEND_URL,
          'Authorization': `Bearer ${access_token}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
```

We also add env vars to our `./erb/frontend-react-js.env.erb` file for our frontend as well as `backend_url` variable, which if you remember, is our invoke URL for our API Gateway. 

```sh
REACT_APP_BACKEND_URL=https://4567-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
REACT_APP_FRONTEND_URL=https://3000-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
REACT_APP_API_GATEWAY_ENDPOINT_URL=https://999999999.execute-api.us-east-1.amazonaws.com
```

Then we update the string path given for `backend_url`. 

```js
const backend_url = '${process.env.REACT_APP_API_GATEWAY_ENDPOINT_URL}/avatars/key_upload'
```

We re-generate our frontend env vars by rerunning our script to do so.

```sh
./bin/frontend/generate-env
```

With new env vars to load, we compose down our environment, then Docker compose up again. In our fresh environemnt from our web app, we log back in. The head back over to our Profile page again and test uploading an image. From Inspect, we're getting a Warning, and we've just cleared a lot of `console.log`'s from our code to try and clean up what we're seeing here. 

![image](https://user-images.githubusercontent.com/119984652/236955591-bca36c22-6f94-4db5-9a6c-e7039f2baf84.png)

We head back over to our workspace in `ProfileForm.js` and heed the suggestion.

```js
export default function ProfileForm(props) {
  const [bio, setBio] = React.useState('');
  const [displayName, setDisplayName] = React.useState('');
```

From what I gather, if the `bio` and `displayName` variables will be used to store text input from the user, it is more appropriate to initialize them with an empty string rather than with what we were using before, which was `0`. This is because `0` is a numerical value, and if the values of `bio` and `displayName` are expected to be strings, then initializing them to `0` could cause issues later on in the code.

We then update the `React.useEffect` hook as well:

```js
  React.useEffect(()=>{
    setBio(props.profile.bio || '');
    setDisplayName(props.profile.display_name);
  }, [props.profile])
```

Adding the `|| ''` expression is a fallback incase `bio` is undefined or null. It sets the value of `bio` to an empty string `''`. 

We refresh our web app and click `Edit Profile` button again. This time there's no warnings. We proceed with attempting to upload an image. We're again getting a CORS error on our fetch.

![image](https://user-images.githubusercontent.com/119984652/236956754-964556c9-1ac7-484a-9b2a-3412eb52fc42.png)

We head back over to Lambda in AWS and view our upload Lambda. We update the `Access-Control-Allow-Origin` header, as our workspace URL has changed. Then we deploy the change. Next, just to make things a little clearer, we update the `backend_url` variable set in `ProfileForm.js` to `gateway_url` instead. 

![image](https://user-images.githubusercontent.com/119984652/236958174-ed6d8680-8052-429c-baad-36505e5b5837.png)

We again refresh our web app and attempt to upload an image. We're now getting a `SyntaxError: Unexpected end of JSON input at s3upload` error. 

![image](https://user-images.githubusercontent.com/119984652/236958750-0cace2c2-5c51-4eef-b493-6f1c3d48f049.png)

We add a `console.log` to see what we're getting for a response. We should be getting back our our headers. We refresh our web app and go through the process again. Looking at Inspect in our browser, it looks like we're getting what we're supposed to be getting.

![image](https://user-images.githubusercontent.com/119984652/236959238-c80e88ea-add9-400b-a223-a4ac41661cd6.png)

There's no errors, but we're not getting back what we're looking for. Back in our code for `ProfileForm.js`, we add a couple `console.log`'s for a response on our `s3upload` function and to see what we're getting for our body. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/2e2f01b3-60c9-4d41-abdc-a963bc7a1317)

After we refresh our web app again, then test the upload, we again view Inspect to see what we're getting back. We're getting back a `ReadableStream`. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/1f89054f-2a52-43ff-9eec-035e89f3c565)

Some more info on `ReadableStream` from ChatGPT:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/8282a06c-c773-4d8e-94ee-8af5b204da22)

We clean up our code in `ProfileForm.js`, then shift our direction to our upload Lambda. Currently, we're passing the name of the image to be uploaded as a hardcoded value.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/6346eba6-8778-4c15-b55e-c8d892933c1a)

Since we're already passing this information during the upload, Andrew suggests he'd like the image name to instead be whatever the Cognito User ID is. We begin updating the Lambda. Since we're now passing data in our Lambda, we view our `s3uploadkey` function in `ProfileForm.js`. We decide to try passing some `body: JSON.stringify(json)` data. This will take the value of `json` and convert it into a JSON string representation. We then add our variable for `json`. 

```js
      const json = {
        extension: "",
        cognito_user_uuid: ""
      }
      const res = await fetch(gateway_url, {
        method: "POST",
        body: JSON.stringify(json),
        headers: {
          'Origin': process.env.REACT_APP_FRONTEND_URL,
          'Authorization': `Bearer ${access_token}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      })
```

Next, for `s3upload`, we pass `extension` and `cognito_user_uuid` to the await for `s3uploadkey`. That will erturn a value for `presignedurl`

```js
const presignedurl = await s3uploadkey(extension, cognito_user_uuid)
```

Then to remove the file extension of the file being uploaded, we define variables for `fileparts` and `extension`. 

```js
    const fileparts = filename.split('.')
    const extension = fileparts[fileparts.length-1]
```

Initially the plan to rename the image to whatever the Congito User ID is was predicated on the idea that we would have that information from the `jwt-verify` process. This isn't going to be the case. We begin talking about how to get that information, and Andrew navigates to his Cloudwatch logs for the upload Lambda to show us.  

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/e42f9380-611d-4b6c-afb6-9082dfe7497f)

Our routes for API Gateway are both running when the upload Lambda is triggered. Andrew explains all `OPTIONS` needs to do is return the CORS data. What this means is we're likely generating the presigned URL twice. We can either create another Lambda to handle CORS, or add conditional code to our upload Lambda function to handle the CORS. We decide to implement the conditional code to the upload Lambda. We need to pass data from the authorizer Lambda from API Gateway to our upload Lambda. We find after asking ChatGPT for suggestions that we could use the Context Object. 

It reads:
"When invoking the target lambda function, you can pass an additional context object as a parameter. The authorizer function ncan add the authorization information to this object, and the target function can access it using the 'context' parameter. This approach is useful when you want to pass more complex data structures or multiple values."

We move over to the upload Lambda and view the code through AWS. We already have `context` as a parameter, so we add a `puts` for it to print the values to the console. 

```rb
def handler(event:, context:)
  puts "Context"
  puts context
  puts "Event"
  puts event
```

We deploy the change to our Lambda. We move back over to our web app and refresh. We trigger the Lambda function by testing the upload again. We view Inspect. There's something wrong with our `presignedurl`. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/42322d10-3106-44e2-b351-e273354c3a35)

We head back over to `ProfileForm.js`. We view our `s3uploadkey` where we were previously attempting to pass data. We need to pass `extension`, so we add it as a parameter to `s3uploadkey`. We also modify the `extension` property of `json` and stop passing `cognito_user_uuid` by removing it from the code. Then, we `console.log` out our `extension` to make sure it's returning our file extension as intended. 

```js
  const s3uploadkey = async (extension)=> {
    console.log('ext',extension)
    try {
      const gateway_url = `${process.env.REACT_APP_API_GATEWAY_ENDPOINT_URL}/avatars/key_upload`
      await getAccessToken()
      const access_token = localStorage.getItem("access_token")
      const json = {
        extension: extension
      }
```

This time when we refresh our web app and inspect, we're getting back our extension.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/a51c6d3b-f642-437c-ba7d-14f5c1fd4b3d)

We head back over to CloudWatch to view the logs of the upload Lambda. We're now getting back our `context` that we added a `put` for in our authorizer Lambda earlier. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/f754fc8b-c5b0-4c12-af5f-f7a95e953ce3)

We do a bit of research on `LambdaContext` and find that we should be able to get the Cognito user ID by adding the `identity` property to our `context` parameter. We make the change to our Lambda function.

```rb
def handler(event:, context:)
  puts "Context Identity"
  puts context.identity
  puts context.identity.inspect
  puts "Event"
  puts event
```

We deploy the change and test it by refreshing our web app and testing the upload. Then, we view the CloudWatch logs.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/7b6e3b84-8005-49cb-bf1e-3a01add684b7)

It's returning `nil`. Andrew believes this is likely because the property could be talking about identity pools in Cognito, not user pools. We change our approach and try another suggestion from ChatGPT: using the Lambda Proxy Integration. The authorizer Lambda can return a JSON response that includes an "Authorization" key-value pair in the header object. The upload Lambda can then access this information from the event object's "header's" property. We begin implementing the changes to our upload Lambda via our workspace.

```rb
def handler(event:, context:)
  puts event
  # return cors headers for preflight check
  if event['routeKey'] == "OPTIONS /{proxy+}"
    puts({step: 'preflight', message: 'preflight CORS check'}.to_json)
    { 
      headers: {
        "Access-Control-Allow-Headers": "*, Authorization",
        "Access-Control-Allow-Origin": "https://3000-jhargett1-awsbootcampcru-2n1d6e0bd1f.ws-us94.gitpod.io",
        "Access-Control-Allow-Methods": "OPTIONS,GET,POST"
      },
      statusCode: 200
    }
```

In this first section, the function checks if the HTTP request method is `OPTIONS` and the route is `/proxy+`. If so, it returns a set of CORS headers as a response for a preflight CORS check. The returned headers allow access to our API Gateway. 

We work through several syntax errors, refreshing our web app, testing the upload, then viewing the CloudWatch logs each time. Eventually, there's no more syntax errors, instead Andrew receives this error:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/81fffc92-3099-43c2-8a2a-2a16a2ca6712)

At this point, I'm not receiving the same errors Andrew is, but more on that later. I continue on with instruction. This error indicates that the `jwt` module isn't found. We go over to our `./aws/lambdas/cruddur-upload-avatars/Gemfile` and add the dependency:

```Gemfile
gem "jwt"
```

We cd over to the directory, then run a `bundle install` from the terminal. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/a5bd2687-6bff-47f0-8288-6687195ceecb)

Just as we did with our authorizer Lambda previously, we download the contents of our `./aws/lambdas/cruddur-upload-avatars` directory locally, then zip the files. Next we move back over to our upload Lambda in AWS and upload a `.zip` file. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/fd93da9e-8ef6-4110-87a7-4570e4e7aa75)

Our next testing of this from our web app completes and we go back to CloudWatch to view the logs again. Once again, we're receiving the `"Cannot load such file -- jwt"` error. We decide to implement a Lambda layer to install this dependency since this is not working. We create a new directory in our `./bin` folder named `lambda-layers`, then a new script therein named `ruby-jwt`. 

```sh
#! /usr/bin/bash

gem i jwt -Ni /tmp/lambda-layers/ruby-jwt/ruby/gems/2.7.0
cd /tmp/lambda-layers/ruby-jwt

zip -r lambda-layers . -x ".*" -x "*/.*"
zipinfo -t lambda-layers

aws lambda publish-layer-version \
    --layer-name jwt \
    --description "Lambda Layer for JWT" \
    --license-info "MIT" \
    --zip-file fileb://lambda-layers.zip \
    --compatible-runtimes ruby2.7
```

In the script above, we are installing the `gem` for `jwt` to the `/tmp/lambda-layers/ruby-jwt/ruby/gems/2.7.0`  temporary directory. We then cd over to the `/tmp/lambda-layers/ruby-jwt` directory, zip the directory and its contents, excluding hidden files and directories. Then the integrity of the zip folder is checked. Finally, we use the `aws lambda publish-layer-version` command to create our Lambda layer named `jwt` and passing the `.zip` file we just created as the code for the layer. 

We run the script.

```sh
./bin/lambda-layers/ruby-jwt
```

The script completes, so we head back over to our upload Lambda in AWS. From our upload Lambda, we scroll down on the Code tab and find Lambda Layers. We add a new layer, select Custom Layers, then select our `jwt` layer we just created.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/ad308a65-e03c-4d01-9d5a-3ed4768ab97a)

We add the layer, then deploy the Lambda. Next, we head back over to our web app and refresh, then test the upload again. Now, we head back to CloudWatch to view the logs. Andrew's logs return the `presignedurl` and `access_token`. His works. Mine again, does not. But again, I press on with instruction. With the Lambda working correctly now for Andrew, the `access_token` is now decoded, and we have our `sub` which is the Cognito User ID. We can now use this as the identifier for our avatar. We move back over to our workspace to continue updating our upload Lambda. 

```rb
require 'aws-sdk-s3'
require 'json'
require 'jwt'

def handler(event:, context:)
  puts event
  # return cors headers for preflight check
  if event['routeKey'] == "OPTIONS /{proxy+}"
    puts({step: 'preflight', message: 'preflight CORS check'}.to_json)
    { 
      headers: {
        "Access-Control-Allow-Headers": "*, Authorization",
        "Access-Control-Allow-Origin": "https://3000-omenking-awsbootcampcru-2n1d6e0bd1f.ws-us94.gitpod.io",
        "Access-Control-Allow-Methods": "OPTIONS,GET,POST"
      },
      statusCode: 200
    }
  else
    token = event['headers']['authorization'].split(' ')[1]
    puts({step: 'presignedurl', access_token: token}.to_json)

    body_hash = JSON.parse(event["body"])
    extension = body_hash["extension"]

    decoded_token = JWT.decode token, nil, false
    cognito_user_uuid = decoded_token[0]['sub']

    s3 = Aws::S3::Resource.new
    bucket_name = ENV["UPLOADS_BUCKET_NAME"]
    object_key = "#{cognito_user_uuid}.#{extension}"

    puts({object_key: object_key}.to_json)

    obj = s3.bucket(bucket_name).object(object_key)
    url = obj.presigned_url(:put, expires_in: 60 * 5)
    url # this is the data that will be returned
    body = {url: url}.to_json
    { 
      headers: {
        "Access-Control-Allow-Headers": "*, Authorization",
        "Access-Control-Allow-Origin": "https://3000-jhargett1-awsbootcampcr-q4kf60g115r.ws-us94.gitpod.io",
        "Access-Control-Allow-Methods": "OPTIONS,GET,POST"
      },
      statusCode: 200, 
      body: body 
    }
  end # if 
end # def handler
```

In the updated Lambda, if the incoming event is not a preflight check, the function first extracts the extension of the file to be uploaded from the JSON body of the request. Then, it decodes the JWT token in the Authorization header to get the Cognito User ID. We deploy the change to our Lambda, then head back over to our web app and refresh, then test the upload again. Then, we head back over to CloudWatch again. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/c07e2280-9ed7-40ca-9443-9ec19f95a9f1)

Andrew's logs are now returning the Cognito User ID passed as the `object_key`. We head over to S3 and view Andrew's upload bucket. It uploaded the image, naming the file the Cognito User ID. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/a92e97d6-4d99-4b36-af4f-7828c296b75e)

I'm not having the same results. When I attempt to upload an image and use Inspect, I'm getting 404 undefined on the PUT and a CORS error. My `gateway_url` is returning undefined as well. I suspected an issue with my API Gateway, as the `gateway_url` is returning undefined. When I would view my CloudWatch logs, I would pass the preflight check, but that's it.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/69106647-fea4-4a48-8b2c-1dbc7e9a427d)

If I bypassed CORS by setting it in API Gateway completely wide open (basically giving a * value for everything), then it would appear to work correctly. When my troubleshooting steps failed, I went to our fellow bootcampers for assistance, creating a thread in our private Discord. I worked on this back and forth with fellow bootcamper @F4dy quite exhaustively until even he said everything appeared correct. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/4b4d667b-f116-40ea-acd3-69dd71ac76a4)

It wasn't until I was able to troubleshoot with Andrew during a bootcamp Office hours study/homework group session that we were able to figure it out. When we added the `OPTIONS` route to our API Gateway, my CORS was still setup or cached to the previous configuration. Andrew was assisting me and had me clear the CORS settings from API Gateway in AWS. Previously, I had done this by manually clearing each field. Clicking the Clear button instead must've shook something loose, because once I did that, my Lambda ran correctly! I was able to test again, then check my CloudWatch logs.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/347e77f0-70ce-40f7-9c95-6f58843dd2af)

Moving forward from here, now all that's left to do is implement the upload to our web app. Or I should clarify. Our upload is working, we just need to implement it by displaying the updated image. 
