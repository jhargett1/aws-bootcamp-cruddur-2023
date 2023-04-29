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

![image](https://user-images.githubusercontent.com/119984652/235318472-7488d7c2-baad-45e5-9293-118edba7dbef.png

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

The script completes without any issue. 

