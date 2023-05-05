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

Also since this is `TypeScript` we have to explicitly state what is being returned. We're returning the `bucket` but on the first line above, we're returning it as an `s3.IBucket`. Per ChatGPT for added detail: `"  In TypeScript, s3.IBucket is an interface that defines the shape of an S3 bucket object, but does not provide the implementation details. The s3.Bucket object is returned, which satisfies the s3.IBucket interface, since s3.Bucket implements the IBucket interface. This returned object can then be used to interact with the S3 bucket, using the methods and properties provided by the s3.Bucket class."`

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

