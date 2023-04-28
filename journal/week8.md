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

Kristi explains we set our scope. `this` is literally this construct we are building. The `id` we're setting is `'ThumbingBucket'`.
