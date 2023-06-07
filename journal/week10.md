# Week 10 — CloudFormation Part 1

We started off CloudFormation with a guest instructor Rohini Gaonkar, an AWS Sr. Dev Advocate leading instruction along with Andrew. We walked through setting up a basic CloudFormation template deploying an ECS Cluster. We also created a `deploy` script that deployed the cluster, along with a new S3 bucket named `jh-cfn-artifacts`.  In addition to this, we add a task to our `.gitpod.yml` file to install `cfn-lint`. Per ChatGPT, "`cfn-lint` is a tool used for linting CloudFormation templates, which checks for syntactical errors, best practices, and adherence to standards. It ensures the correctness and quality of the CloudFormation template."  

My main takeaway from this walkthrough to start our week off was that a lot of, if not most of what you will need to implement CloudFormation templates will be in the AWS documentation for it, which is quite vast. 

## Networking Layer

Moving onto main instruction, we now have a `cfn` folder created during the livestream in our `./aws` directory. We create a new folder within this directory named `networking`. Next we create a new file in this folder named `template.yaml`. We begin, just fleshing out the `template.yaml`, commenting what we're going to need.

```yaml
AWSTemplateFormatVersion: 2010-09-09

# VPC
# IGW
# Route Tables
# Subnets
# Subnet A
# Subnet B
# Subnet C
```

We immediately consult AWS documentation for the VPC, which in CloudFormation is known as `AWS::EC2::VPC`. Andrew notes, "by reading through these options you really do learn, how these services work." As I come to find out, he's super correct with this statement. We continue on, reading through each property of the VPC in CloudFormation and begin implementing it. 

```yaml
AWSTemplateFormatVersion: 2010-09-09

# VPC
Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock:
      EnableDnsHostnames: true
      EnableDnsSupport: true
      InstanceTenancy: default
# IGW
# Route Tables
# Subnets
# Subnet A
# Subnet B
# Subnet C
```

Andrew mentions at this point that in effort to get used to doing lots of deploys, we should begin setting that up at this point as well. In our `./bin/cfn` directory, we create a new script named `networking-deploy`. 

```
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/networking/template.yaml"

cfn-lint $CFN_PATH 

aws cloudformation deploy \
    --stack-name "Cruddur" \
    --s3-bucket $CFN_BUCKET \
    --template-file $CFN_PATH \
    --no-execute-changeset \
    --capabilities CAPABILITY_NAMED_IAM
```

We set the value for a variable named `CFN_PATH` to the path for our `template.yaml` file for our network layer. 

Next, we deploy a CloudFormation stack using the `aws cloudformation deploy` command. Here are the options and arguments used:

`--stack-name`: Specifies the name of the stack to create or update. In this case, it's set to "Cruddur".

`--s3-bucket`: Specifies the S3 bucket to upload the CloudFormation template to. The value of the CFN_BUCKET variable is expected to be set somewhere else in the script or in the environment.

`--template-file`: Specifies the path to the CloudFormation template file, which is set to the value of the CFN_PATH variable.

`--no-execute-changeset`: Indicates that the changeset created during the deployment should not be executed immediately. It allows you to review the changes before applying them.

`--capabilities CAPABILITY_NAMED_IAM`: Specifies the IAM capabilities required to create or update IAM resources in the CloudFormation stack. This capability is necessary when the template includes IAM resources.

Andrew notes we're going to continue to use the `jh-cfn-artifacts` S3 bucket we created during the livestream, so we must set the variable for `CFN_BUCKET` as well. 

From our terminal:

```sh
export CFN_BUCKET="jh-cfn-artifacts"
gp env CFN_BUCKET="jh-cfn-artifacts"
```

We also need to note that an S3 bucket is needed, so we create a `Readme.md` file in our `./aws/cfn` directory. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/938a8a13-3a21-4caf-8986-e6d0fe8079fe)

This will act as a disclaimer of what to do prior to running any of our templates. With the `Readme.md` file created, Andrew mentions he's coded a library that we can use to dynamically load parameters in a `.toml` file if needed, but for now we're going to go back to focusing on the CloudFormation. With the script completed, Andrew attempts to run it, so we can see `cfn-lint` at work. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/e238d899-d116-47d3-81db-838d56669cc1)

We have yet to fill in a value for the `CidrBlock` property in our networking `template.yaml` file. We research this, navigating to https://cidr.xyz to determine what we'll use for our CIDR block for our VPC. Andrew further explains this is very important, as this will determine the range of IP addresses that can be assigned to the resources within our VPC and also help us maintain higher availability of our resources. We settle on a size of 16. 

```yaml
AWSTemplateFormatVersion: 2010-09-09

Resources: 
  VPC:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc.html
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      InstanceTenancy: default
```

With this, we again run our `networking-deploy` script. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/0a6b96b2-9e6e-40f5-b0ef-00dd312b2b4a)

We move over to CloudFormation in AWS and execute the changeset. We do so by selecting the Cruddur stack, selecting Change sets, selecting our changeset, then clicking "Execute Changeset". Our resource, the VPC, is being created.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/3b5b45b2-8ccb-4b94-980a-cc3e11c01c90)

When the VPC completes, we found that AWS also automatically creates a route table for you. In sifting through the resources, we had a bit of trouble with our previous configuration resources showing in the console. To remedy this, we decide to name the VPC resource as well, so we add tags to our `template.yaml`. 

```yaml
      Tags:
        - Key: Name
          Value: CruddurVPC
```

This will name our VPC resource as `CruddurVPC`. The next resource we must create is an internet gateway. We go back to AWS documentation and look specifically for `AWS::EC2::InternetGateway`. There's no properties to set for an internet gateway other than tags, so we implement the code: 

```yaml
  IGW:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-internetgateway.html
    Type: AWS::EC2::InternetGateway
    Properties: 
      Tags:
        - Key: Name
          Value: CruddurIGW
```

When we create an internet gateway, we also must tell our CFN template to attach it. We consult AWS documentation for `AWS::EC2::VPCGatewayAttachment` then begin specifying properties. 

```yaml
  AttachIGW:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref VPC
      InternetGatewayId: !Ref IGW
```

You'll note the `!Ref` function being used here. `!Ref VPC` and `!Ref IGW` are used for the `VpcId` and `InternetGatewayId` properties respectively to reference the `VPC` and `IGw` resources defined earlier in the template. AWS documentation per resource will also give return values for the `!Ref` function just in case you're unsure as well. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/e0dd3333-4714-4723-9a77-c0f10f13fcba)

Andrew adds to this by telling us to pay attention to the value each property requires as well, as the `!Ref` function will return different values dependent upon the property of the resource. Always consult the AWS documentation just to be sure. 

With the emphasis given to just how instrumental AWS documentation is for fleshing out our resources in our CloudFormation templates, I'll now begin referring less to the documentation and begin just showing implementation. 

We move on, as we're going to work on routes and route tables. We begin implementing a route table, which is responsible for directing network traffic with our VPC.

```yaml
  RouteTable:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-routetable.html
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC 
      Tags:
        - Key: Name
          Value: CruddurRT
```

Next, we implement a route:

```yaml
  RouteToIGW:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-route.html
    Type: AWS::EC2::Route
    DependsOn: AttachIGW
    Properties:
      RouteTableId: !Ref RouteTable
      GatewayId: !Ref IGW
      DestinationCidrBlock: 0.0.0.0/0
```

Please bring your attention to the `DependsOn` property. This property indicates that `RouteToIGW` will not be created if `AttachIGW` does not exist. So if our gateway is not created, CloudFormation will not create our route either. The `GatewayId` property is returning the logical id of the internet gateway we'd like to use, so we point it towards our `IGW` gateway. We want our route going out to the internet, so we set the `DestinationCidrBlock` to 0.0.0.0/0. The reasoning is, 0.0.0.0/0 represents the entire IPv4 address space in CIDR notation. 

We also implement a route for local as well, but we're uncertain on the `GatewayId`:

```yaml
  RouteToLocal:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-route.html
    Type: AWS::EC2::Route
    DependsOn: AttachIGW
    Properties:
      RouteTableId: !Ref RouteTable
      GatewayId: "local"
      DestinationCidrBlock: 10.0.0.0/16
```

ChatGPT recommended this code snippet above, so we implement it, then try our `networking-deploy` script. It passes `cfn-lint` and a changeset is created. When we execute the changeset from CloudFormation in AWS, it doesn't take long for us to receive a `CREATE_FAILED` error.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/1d05ae97-00b8-4d24-9478-0b2459aea1ab)

"The route identified by 10.0.0.0/16 already exists." is the error received. On a hunch that the route is being created automatically, we comment out the lines of code creating the routes and route table, leaving our VPC, our internet gateway, and our gateway attachment as the only resources to create. Then, we delete our stack from CloudFormation that's in a `ROLLBACK_COMPLETE` state, and redeploy. When the changeset is executed and the create is complete, we go over to EC2 and view our VPC resource. Andrew makes mention that a network ACL is created automatically, and tells us if ever in a bind troubleshooting networking issues through cloud, NACL'S (Network Access Control List) can act as a stateless firewall controlling inbound and outbound traffic at the subnet level of the VPC. Make sure the NACL's have outbound routes, or all internet access will be blocked. 

Moving on, we go over and check the routes created by default. Just as suspected, it created a route automatically for local. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/d1c3d5f8-c03e-42fe-821c-3e2e065a18e2)

We uncomment the lines of code creating our route table and our `RouteToIGW`. Then, we again deploy our networking CFN template. When the changeset is created, we execute it from CFN. When we go back to EC2 to view our our new route table, it automatically created the route to local as well:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/3c24b381-567e-4a08-96d8-59b6d396f533)

Since the route to local is already being created, we remove the commented lines of code creating that route. Next, we must create our subnets. We might decide that our database must sit privately, so in addition to our public subnets, we create private ones as well. 

```yaml
  SubnetPub1:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
    Type: AWS::EC2::Subnet
    Properties:
      AssignIpv6AddressOnCreation: false
      AvailabilityZone: us-east-1a
      CidrBlock: 10.0.0.0/24
      EnableDns64: false
      MapPublicIpOnLaunch: true # public subnet
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: CruddurSubnetPub1
  SubnetPub2:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
    Type: AWS::EC2::Subnet
    Properties:
      AssignIpv6AddressOnCreation: false
      AvailabilityZone: us-east-1b
      CidrBlock: 10.0.4.0/24
      EnableDns64: false
      MapPublicIpOnLaunch: true # public subnet
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: CruddurSubnetPub2  
  SubnetPub3:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
    Type: AWS::EC2::Subnet
    Properties:
      AssignIpv6AddressOnCreation: false
      AvailabilityZone: us-east-1c
      CidrBlock: 10.0.8.0/24
      EnableDns64: false
      MapPublicIpOnLaunch: true # public subnet
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: CruddurSubnetPub3
  SubnetPriv1:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
    Type: AWS::EC2::Subnet
    Properties:
      AssignIpv6AddressOnCreation: false
      AvailabilityZone: us-east-1a
      CidrBlock: 10.0.12.0/24
      EnableDns64: false
      MapPublicIpOnLaunch: false # private subnet
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: CruddurSubnetPriv1  
  SubnetPriv2:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
    Type: AWS::EC2::Subnet
    Properties:
      AssignIpv6AddressOnCreation: false
      AvailabilityZone: us-east-1b
      CidrBlock: 10.0.16.0/24
      EnableDns64: false
      MapPublicIpOnLaunch: false # private subnet
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: CruddurSubnetPriv2
  SubnetPriv3:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
    Type: AWS::EC2::Subnet
    Properties:
      AssignIpv6AddressOnCreation: false
      AvailabilityZone: us-east-1c
      CidrBlock: 10.0.20.0/24
      EnableDns64: false
      MapPublicIpOnLaunch: false # private subnet
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: CruddurSubnetPriv3 
```

A few key takeaways from these properties:

`AssignIpv6AddressOnCreation`: controls whether IPV6 addresses are automatically assigned to instances that are launched in the subnet

`AvailabilityZone`: the availability zone within AWS that our subnet is created in

`EnableDns64`: controls whether DNS64 is enabled for an IPv6 enabled subnet. Since we're not using IPv6, this value is false

`MapPublicIpOnLaunch`: controls the automatic assignment of a public IP address to instances launched within a subnet. Notice our public subnets have this set to true, where our private ones are set to false. 

Next we must implement our `SubnetRouteTableAssocation` resources. This will associate our subnets with our route table in the VPC. 

```yaml
SubnetPub1RTAssociation:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnetroutetableassociation.html
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetPub1
      RouteTableId: !Ref RouteTable  
  SubnetPub2RTAssociation:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnetroutetableassociation.html  
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetPub2
      RouteTableId: !Ref RouteTable  
  SubnetPub3RTAssociation:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnetroutetableassociation.html  
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetPub3
      RouteTableId: !Ref RouteTable  
  SubnetPriv1RTAssociation:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnetroutetableassociation.html  
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetPriv1
      RouteTableId: !Ref RouteTable  
  SubnetPriv2RTAssociation:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnetroutetableassociation.html  
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetPriv2
      RouteTableId: !Ref RouteTable  
  SubnetPriv3RTAssociation:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnetroutetableassociation.html  
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetPriv3
      RouteTableId: !Ref RouteTable
```

You'll notice the only properties are asking for the subnet and route table of which to associate. 

With this completed, we now try to deploy our `template.yaml` for our networking layer again. This time, `cfn-lint` gives us some feedback.

![1 12 02 into CFN for networking layer dont hardcode for availability zones warning](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/4a76148e-cd13-4824-b6a9-9878304fb522)

Andrew explains these are warnings, we're not actually going to hardcode values for our availability zones. To circumvent these warnings, we go ahead and pass some parameters in our networking template. 

```yaml
Parameters:
  Az1:
    Type: AWS::EC2::AvailabilityZone::Name
    Default: us-east-1a
  Az2:
    Type: AWS::EC2::AvailabilityZone::Name
    Default: us-east-1b
  Az3:
    Type: AWS::EC2::AvailabilityZone::Name
    Default: us-east-1c   
```

Then we use the `!Ref` function to pass the values in our template, per subnet. For example:

```yaml
AvailabilityZone: !Ref Az1
```

We again deploy the CFN template, this time the changeset is created. We execute it via AWS. The create fails this time, stating the `IPv6CidrBlock` cannot be empty. We review AWS documentation to see why.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/b317cde4-52d4-4b37-a46c-031f3bca6bb4)

Per the snippet above, since we specified `AssignIpv6AddressOnCreation`, we must also specify `Ipv6CidrBlock`. Since neither is being used, we just remove the `AssignIpv6AddressOnCreation` property from our template. With the template file updated, we again run our `networking-deploy` script. We execute the changeset from CloudFormation and we have an `UPDATE_COMPLETE` status. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/4416f5ce-d7f3-4b4c-a775-4175da0a203e)

Moving on, Andrew explains that we're not going to implement security groups at this layer, because security groups are usually around particular services. We also decide we want to clean things up in our code a little bit, particularly our `CidrBlock` properties. We do this by implementing some parameters:

```yaml
Parameters:
  SubnetCidrBlocks: 
    Description: "Comma-delimited list of CIDR blocks for our private public subnets"
    Type: CommaDelimitedList
    Default: > 
      10.0.0.0/24, 
      10.0.4.0/24, 
      10.0.8.0/24, 
      10.0.12.0/24, 
      10.0.16.0/24, 
      10.0.20.0/24   
```

You'll note that we're using a Comma Delimited List for our `SubnetCidrBlocks` parameter. Andrew explains how we're implementing this by using what's known as a scalar variable in Yaml. He shows us a slide from an unreleased course detailing this. A scalar is "a variable that holds one value at a time. Scalars are generally primitive data types e.g. String, Int, Bool". We're using what's known as a folded block scalar style, using the folded start with a `>`. This allows CloudFormation to treat our parameter as a single string. 

We're able to reference these values for our `CidrBlock` property by using the `!Select` function. 

```yaml
CidrBlock: !Select [0, !Ref SubnetCidrBlocks]
```

In the above code snippet, we're selecting the first element from the list of subnet CIDR blocks, i.e. 10.0.0.0/24. 

We also add a parameter for our VPC `CidrBlock` property as well. 

```yaml
Parameters:
  VpcCidrBlock:
    Type: String
    Default: 10.0.0.0/16
```

We then pass the value of the parameter to the property using the `!Ref` function.

```yaml
Resources: 
  VPC:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc.html
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidrBlock
```

From there, we update the tags for all of our resources that have them in our `template.yaml` to utilize pseudo parameters from AWS, in this instance, the `AWS::StackName` parameter for our VPC. 

```yaml
      Tags:
        - Key: Name
          Value: !Sub "${AWS::StackName}VPC"
```

In AWS CloudFormation, pseudo parameters are predefined variables that you can use in your CloudFormation templates. These parameters are automatically available and can provide information about the stack, region, AWS account, and other contextual information at the time of stack creation. Some further information on pseudo parameters from ChatGPT:

"Pseudo parameters are resolved by CloudFormation during the stack creation or update process. They are not defined explicitly in the template, but rather they are automatically provided by AWS when the template is processed. Pseudo parameters are denoted by the `AWS::` prefix.

Here are some examples of commonly used pseudo parameters in AWS CloudFormation:

`AWS::AccountId`: Represents the AWS account ID associated with the stack.
`AWS::Region`: Represents the AWS region where the stack is being created.
`AWS::StackName`: Represents the name of the stack.
`AWS::StackId`: Represents the unique ID of the stack.
`AWS::NotificationARNs`: Represents a comma-separated list of notification Amazon Resource Names (ARNs) for the current stack.

You can use these pseudo parameters within your template to dynamically reference or incorporate information about the stack or AWS environment. For example, you can use `AWS::Region` to ensure resources are created in the correct region or use `AWS::AccountId` to create unique resource names based on the AWS account ID.

Note that pseudo parameters are read-only, and you cannot assign values to them or modify their behavior."

With these changes implemented, we're not building anything extra in the `template.yaml`, we're just updating some naming and how our `CidrBlock` properties are read. With that in mind, to make sure it works, we go back to CloudFormation and tear down our stack. Next we redeploy using our `networking-deploy` script. After the changeset is created, we execute it. While that's being created, we go back to our workspace and begin working on some Outputs. Adding outputs will allow us to expose information about our resources created by the stack. We'll be able to use these outputs for other stacks when we implement future layers. 

```yaml
Outputs:
  VpcId:
    Value: !Ref VPC
    Export:
      Name: VpcId
  VpcCidrBlock:
    Value: !GetAtt VPC.CidrBlock
    Export:
      Name: VpcCidrBlock
  SubnetCidrBlocks:
    Value: !Join [",", !Ref SubnetCidrBlocks]
    Export:
      Name: SubnetCidrBlocks
  SubnetIds: 
    Value: !Join 
      - "," 
      - - !Ref SubnetPub1 
        - !Ref SubnetPub2 
        - !Ref SubnetPub3 
        - !Ref SubnetPriv1
        - !Ref SubnetPriv2
        - !Ref SubnetPriv3
    Export: 
      Name: SubnetIds
  AvailabilityZones:
    Value: !Join 
      - "," 
      - - !Ref Az1
        - !Ref Az2
        - !Ref Az3  
    Export: 
      Name: AvailabilityZones
```

Let's breakdown each output:

`VpcId`: This output references the VPC resource using `!Ref VPC`. It exports the value with the name `VpcId`. This output can be referenced in other stacks to retrieve the VPC ID.

`VpcCidrBlock`: This output uses the `!GetAtt` function to retrieve the `CidrBlock` attribute of the `VPC` resource. It exports the value with the name `VpcCidrBlock`. This output provides the CIDR block of the VPC.

`SubnetCidrBlocks`: This output uses the `!Join` function to concatenate the values of `SubnetCidrBlocks`, which are referenced by `!Ref SubnetCidrBlocks`, separated by commas. It exports the joined value with the name `SubnetCidrBlocks`. This output provides a comma-separated list of subnet CIDR blocks.

`SubnetIds`: This output uses the `!Join` function to concatenate the values of `SubnetPub1`, `SubnetPub2`, `SubnetPub3`, `SubnetPriv1`, `SubnetPriv2`, and `SubnetPriv3` separated by commas. The subnet values are obtained using `!Ref` for each subnet. It exports the joined value with the name `SubnetIds`. This output provides a comma-separated list of subnet IDs.

`AvailabilityZones`: This output uses the `!Join` function to concatenate the values of `Az1`, `Az2`, and `Az3` separated by commas. The availability zone values are obtained using !Ref for each availability zone. It exports the joined value with the name `AvailabilityZones`. This output provides a comma-separated list of availability zones.

When we again deploy then execute the changeset from CloudFormation,  we now have Outputs available under the Outputs tab. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/dece2220-acea-4577-8c6f-51d919b5db20)

This completes the networking layer. 

## Cluster Layer

Next, we are going to implement our Cluster layer to define our Fargate cluster. Back in our workspace, we create a new folder named `cluster` in the `./aws/cfn` directory. We create a new file in the folder named `template.yaml`, then create a new script in our `./bin/cfn` directory named `cluster-deploy`. We again start off by fleshing out our `template.yaml`, and we also pull over the resource we created during our livestream.

```yaml
AWSTemplateFormatVersion: 2010-09-09

# Parameters:
Resources:
  ECSCluster: #LogicalName
    Type: 'AWS::ECS::Cluster'
    Properties:
      ClusterName: MyCluster1
      CapacityProviders:
        - FARGATE
# Outputs:

```

You can see we're creating an ECS Cluster resource. We continue on with this, adding properties for the cluster:

```yaml
AWSTemplateFormatVersion: 2010-09-09

# Parameters:
Resources:
  FargateCluster:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ecs-cluster.html 
    Type: AWS::ECS::Cluster
    Properties: 
      ClusterName: !Sub "${AWS::StackName}FargateCluster"
      CapacityProviders: 
        - FARGATE 
      ClusterSettings: 
        - Name: containerInsights
          Value: enabled
      Configuration: 
        ExecuteCommandConfiguration:
          Logging: DEFAULT
      ServiceConnectDefaults: 
        Namespace: cruddur
# Outputs:
```

Some information on the properties of the cluster: 

`CapacityProviders`: This property specifies the capacity providers to associate with the cluster. In this case, it has a single value `FARGATE`, indicating that the cluster should use AWS Fargate capacity provider.

`ClusterSettings`: This property allows you to configure additional settings for the cluster. In this case, it specifies a setting named `containerInsights` with the value enabled, enabling the CloudWatch Container Insights feature.

`Configuration`: This property allows you to specify additional configurations for the cluster. Here, it includes the `ExecuteCommandConfiguration` property with Logging set to `DEFAULT`, which configures the default logging behavior for execute command functionality.

`ServiceConnectDefaults`: This property allows you to specify a default Service Connect namespace. Once the default namespace is set, any new services with Service Connect turned on that are created in the cluster are added as client service in the namespace. We set the `Namespace` property to `cruddur`.

While working through AWS documentation for this, we come upon the `Description` section and decide to go back and add this to our networking layer `template.yaml`.

```yaml
Description: |
  The base networking components for our stack:
  - VPC
    - sets DNS hostnames for EC2 instances
    - Only IPv4, IPv6 is disabled
  - InternetGateway 
  - Route Table
    - Route to the IGW
    - Route to Local
  - 6 Subnets Explicitly Associated to Route Table
    - 3 Public Subnets numbered 1 to 3
    - 3 Private Subnets numbered 1 to 3
```

We begin working on the `cluster-deploy` script now as well by copying our `networking-deploy` script as a start off point, then editing it down. 

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/cluster/template.yaml"

cfn-lint $CFN_PATH 

aws cloudformation deploy \
    --stack-name "Cruddur" \
    --s3-bucket $CFN_BUCKET \
    --template-file $CFN_PATH \
    --no-execute-changeset \
    --tags group="cruddur-cluster" \
    --capabilities CAPABILITY_NAMED_IAM
```

You'll notice the `CFN_PATH` is now updated to the path for our cluster `template.yaml` file, and we're also propagating down tags from the CloudFormation commands. We go back to our `networking-deploy` script and implement the tags there as well. Then, we move forward with implementing our cluster layer through the `template.yaml`. We add an application load balancer.

```yaml
  ALB:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-elasticloadbalancingv2-loadbalancer.html
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub "${AWS::StackName}ALB"
      Type: application
      IpAddressType: ipv4
      # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-elasticloadbalancingv2-loadbalancer-loadbalancerattributes.html
      Scheme: internet-facing
      SecurityGroups: 
        - security group ids
      Subnets: 
      LoadBalancerAttributes: 
        - Key: routing.http2.enabled
          Value: true
        - Key: routing.http.preserve_host_header.enabled
          Value: false
        - Key: deletion_protection.enabled
          Value: true
        - Key: load_balancing.cross_zone.enabled
          Value: true
        - Key: access_logs.s3.enabled
          Value: false
          # In case we want to turn on logs
        # - Key: access_logs.s3.bucket
          # Value: bucket-name
        # - Key: access_logs.s3.prefix
          # Value: ""
```

Remember that we have left the `Subnets` property blank for now. More details on the properties we're setting here:

`Type`:  Indicates the type of load balancer. In this case, it is set to application, which represents an application load balancer.

`IpAddressType`: Specifies the IP address type for the ALB. Here, it is set to `ipv4`, indicating the use of IPv4 addresses. It is the most common choice and allows the ALB to handle traffic over IPv4. The other option we could've selected is `dualstack`. This option specifies that the ALB should use both IPv4 and IPv6 addresses. It enables the ALB to handle traffic over both IPv4 and IPv6 protocols

`LoadBalancerAttributes`: Specifies a list of load balancer attributes and their corresponding values. Each attribute is represented as a dictionary with a Key and Value pair.

`Key: routing.http2.enabled`: Enables HTTP/2 routing for the ALB.

`Key: routing.http.preserve_host_header.enabled`: Enables preserving the host header for HTTP routing. When set to false, the host header is not preserved when forwarding requests to the target groups.

`Key: deletion_protection.enabled`: Enables deletion protection for the ALB. When deletion protection is enabled, the ALB cannot be deleted accidentally.

`Key: load_balancing.cross_zone.enabled`: Enables cross-zone load balancing. When enabled, the ALB evenly distributes traffic across all availability zones specified in the subnets property.

`Key: access_logs.s3.enabled`: Enables access logs to be stored in Amazon S3. When set to false, no access logs will be generated and stored.

We also commented out a couple of lines of code that would enable logging of our S3 bucket with a name value given by us, which would capture detailed information about every request made to the bucket, such as the requester's IP address, the time of the request, the HTTP status code, and more. The `access_logs.s3.prefix` property specifies a prefix or a directory within the access logging S3 bucket where the logs should be stored. By using a prefix, you can organize and categorize the logs based on specific criteria, such as by date, requester, or any other relevant information.

Also notice that our `SecurityGroups` property does not have a valid value yet. We must create our security groups as well to reference the logical ID of the SG. We continue on with fleshing out the cluster template, adding a `Descritpion` field to the template.

```yaml
Description: |
  The networking and cluster configuration to support Fargate containers:
  - ECS Fargate Cluster
  - Application Load Balancer (ALB)
    -IPv4 only
    - internet facing
  - ALB Security Group
  - HTTPS Listener
    - send root domain to frontend Target Group
    - send API subdomain to backend Target Group
  - HTTP Listener
    - redirects to HTTPS Listener
  - Backend Target Group
  - Frontend Target Group
```

A `Description` field in a CFN template provides an overview of what the template does. It's not mandatory for a CFN template, but it is considered a good practice to include it, as it can help other team members, stakeholders, or reviewers understand the purpose and functionality of the template. 

Before we implement security groups, we must add the listeners for our HTTP and HTTPS. As noted in our `Description`, the HTTPS Listener will send HTTPS requests from our ALB to our frontend target group and send API requests to our backend target group. The HTTP listener will redirect to the HTTPS listener. 

```yaml
  HTTPSListener:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-elasticloadbalancingv2-listener.html
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      Protocol: HTTPS    
      Port: 443
      LoadBalancerArn: !Ref ALB           
      Certificates: 
        - CertificateArn: !Ref CertificateArn
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref FrontendTG
  HTTPListener: 
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-elasticloadbalancingv2-listener.html
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      Protocol: HTTP
      Port: 80
      LoadBalancerArn: !Ref ALB        
      DefaultActions:
        - Type: redirect
          RedirectConfig:
            Protocol: "HTTPS"
            Port: 443
            Host: "#{host}"
            Path: "/#{path}"
            Query: "#{query}"
            StatusCode: "HTTP_301"
```

We're passing a parameter as the value for `CertificateArn`. The parameter is called `CertificateArn`, so we add this as a parameter as well. 

```yaml
Parameters:
  CertificateArn:
    Type: String
    
```

The properties we're using for the listeners here are fairly self explanatory, but I'll dig in a bit here: 

For our `HTTPSListener`: 

`Protocol`: Sets the listener's protocol to HTTPS, indicating that it will handle incoming HTTPS traffic.

`Port`: Defines the port number on which the listener will listen for HTTPS requests (port 443 in this case).

`LoadBalancerArn`: Refers to the ARN of the ALB to which the listener will be attached.

`Certificates`: Specifies the SSL/TLS certificate to be used for encrypting and decrypting HTTPS traffic. It references the certificate ARN using the !Ref intrinsic function.

`DefaultActions`: Defines the default action to be taken by the listener when it receives a request. In this case, it is set to forward the request to a target group referenced by `FrontendTG`, which we will define a bit further down.

For our `HTTPListener`:

`DefaultActions`: Defines the default action to be taken by the listener when it receives a request. In this case, it is set to redirect the request to HTTPS using the specified `RedirectConfig`.

`Type`: Specifies the action type as "redirect".

`RedirectConfig`: Provides configuration options for the redirect action, including the target protocol (HTTPS), port (443), host, path, query, and status code (`HTTP_301` indicating a permanent redirect).


From here, we add our application load balancer security group, or `ALBSG`. 

```yaml
  ALBSG:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html
    Type: AWS::EC2::SecurityGroup
    Properties: 
      GroupName: !Sub "${AWS::StackName}AlbSG"
      GroupDescription: Public Facing SG for our Cruddur ALB
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: '0.0.0.0/0'
          Description: INTERNET HTTPS
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: '0.0.0.0/0'
          Description: INTERNET HTTP
```

The properties defined here `GroupName` and `GroupDescription` sets the name and provides a description of the security group. The name cannot start with "sg" and the `GroupDescription` is a required property. There's a couple rules set in the `SecurityGroupIngress` property that I'll explain further: 

The first rule allows TCP traffic on port 443 (HTTPS) from any source IP (0.0.0.0/0) and provides a description indicating that it is for internet HTTPS traffic.

```yaml
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: '0.0.0.0/0'
          Description: INTERNET HTTPS
```

The second rule allows TCP traffic on port 80 (HTTP) from any source IP (0.0.0.0/0) and provides a description indicating that it is for internet HTTP traffic.

```yaml
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: '0.0.0.0/0'
          Description: INTERNET HTTP
```

With our security group defined, we can now go back to our load balancer to define the security group property:

```yaml
  ALB:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-elasticloadbalancingv2-loadbalancer.html
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub "${AWS::StackName}ALB"
      Type: application
      IpAddressType: ipv4
      # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-elasticloadbalancingv2-loadbalancer-loadbalancerattributes.html
      Scheme: internet-facing
      SecurityGroups: 
        - !Ref ALBSG
```

We're returning the logical ID of the `ALBSG` for our `SecurityGroups` property above. We check the previous configuration prior to CFN through AWS, and in keeping with what we defined in our description, we must add an additional rule for our HTTPS Listener to redirect API requests to our backend target group, which we've yet to define as well. To do this, we add a Listener Rule.

```yaml
  ApiALBListenerRule:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-elasticloadbalancingv2-listenerrule.html
    Type: AWS::ElasticLoadBalancingV2::ListenerRule
    Properties:
      Conditions: 
        - Field: host-header
          HostHeaderConfig: 
            Values: 
              - api.thejoshdev.com
      Actions: 
        - Type: forward
          TargetGroupArn: !Ref BackendTG
      ListenerArn: !Ref HTTPSListener
      Priority: 1
```

Here's a further breakdown of our properties: 

`Conditions`: Specifies the conditions that must be met for the rule to be applied. 

`Field`: Sets the condition field to "host-header", which means the rule will be applied based on the value of the host header in the incoming request. The host header indicates the specific host or domain the HTTP request wants to communicate with. The host header allows the server to identify which virtual host or website the client is targeting when multiple websites or applications are hosted on the same server.

`HostHeaderConfig`: Specifies the configuration for the host header condition.

`Values`: Sets the expected value for the host header to `api.thejoshdev.com`. The rule will match requests with this host-header value.

The `Actions` properties forwards the requests that are matched with the host-header set in our `Conditions`, in this case, `api.thejoshdev.com` and forwards them to the `BackendTG` target group, which we still need to define. 

The `Priority` property sets the priority of the rule to 1, which determines the order of rules to be evaluated. The lower the number, the higher the priority.

We are now ready to define our `BackendTG` and `FrontendTG` target groups that we've referenced in our cluster `template.yaml`. 

```yaml
  BackendTG:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-elasticloadbalancingv2-targetgroup.html
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties: 
      Name: !Sub "${AWS::StackName}BackendTG"
      Port: !Ref BackendPort
      HealthCheckEnabled: true      
      HealthCheckProtocol: !Ref BackendHealthCheckProtocol         
      HealthCheckIntervalSeconds: !Ref BackendHealthCheckIntervalSeconds
      HealthCheckPath: !Ref BackendHealthCheckPath
      HealthCheckPort: !Ref BackendHealthCheckPort
      HealthCheckTimeoutSeconds: !Ref BackendHealthCheckTimeoutSeconds
      HealthyThresholdCount: !Ref BackendHealthyThresholdCount
      UnhealthyThresholdCount: !Ref BackendUnhealthyThresholdCount
      IpAddressType: ipv4
      Matcher: 
        HttpCode: 200
      Protocol: HTTP
      ProtocolVersion: HTTP2
      TargetGroupAttributes: 
        - Key: deregistration_delay.timeout_seconds
          Value: 0
      VpcId: CROSS_REFERENCE_STACK    
  FrontendTG:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-elasticloadbalancingv2-targetgroup.html
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties: 
      Name: !Sub "${AWS::StackName}FrontendTG"
      Port: !Ref FrontendPort
      HealthCheckEnabled: true      
      HealthCheckProtocol: !Ref FrontendHealthCheckProtocol         
      HealthCheckIntervalSeconds: !Ref FrontendHealthCheckIntervalSeconds
      HealthCheckPath: !Ref FrontendHealthCheckPath
      HealthCheckPort: !Ref FrontendHealthCheckPort
      HealthCheckTimeoutSeconds: !Ref FrontendHealthCheckTimeoutSeconds
      HealthyThresholdCount: !Ref FrontendHealthyThresholdCount
      UnhealthyThresholdCount: !Ref FrontendUnhealthyThresholdCount
      IpAddressType: ipv4
      Matcher: 
        HttpCode: 200
      Protocol: HTTP
      ProtocolVersion: HTTP2
      TargetGroupAttributes: 
        - Key: deregistration_delay.timeout_seconds
          Value: 0
      VpcId: CROSS_REFERENCE_STACK
```

Some key takeaways from the properties we defined for our target groups that I haven't referenced yet:

`HealthCheckEnabled`: Indicates whether health checks are enabled for the target group. It is set to true.

`HealthCheckProtocol`: References the protocol used for health checks. 

`HealthCheckIntervalSeconds`: References the interval between health checks in seconds. 

`HealthCheckPath`: References the path used for health checks. 

`HealthCheckPort`: References the port used for health checks. 

`HealthCheckTimeoutSeconds`: References the timeout for health checks in seconds. 

`HealthyThresholdCount`: References the number of consecutive successful health checks required to mark a target as healthy.

`UnhealthyThresholdCount`: References the number of consecutive failed health checks required to mark a target as unhealthy.

`Matcher`: Defines the HTTP response code used to determine the health of a target.

`TargetGroupAttributes`: An array property that allows you to define multiple attributes for the target group.

I asked ChatGPT to break down the `TargetGroupAttributes` property a little bit further, as I wanted to understand this property more as well, specifically the `Key` value: 

"`Key: deregistration_delay.timeout_seconds` specifies the attribute key as `deregistration_delay.timeout_seconds`. This key refers to the attribute that controls the amount of time a target is kept in the "draining" state after it is deregistered from the target group. The "draining" state allows existing connections to complete before the target is completely removed." 

With that information, we know that the `Value` property then sets that value to `0`, which will mean the target will immediately be removed from the target group once it's deregistered. 

We're also passing a lot of parameters here, so we add them to our `Parameters` section of the template.

```yaml
Parameters:
  CertificateArn:
    Type: String
  # Frontend -----------
  FrontendPort:
    Type: Number
    Default: 3000      
  FrontendHealthCheckIntervalSeconds:
    Type: Number
    Default: 15
  FrontendHealthCheckPath: 
    Type: String
    Default: "/"
  FrontendHealthCheckPort: 
    Type: String
    Default: 80
  FrontendHealthCheckProtocol: 
    Type: String
    Default: HTTP
  FrontendHealthCheckTimeoutSeconds: 
    Type: Number
    Default: 5
  FrontendHealthyThresholdCount: 
    Type: Number
    Default: 2
  FrontendUnhealthyThresholdCount: 
    Type: Number
    Default: 2
  # Backend -----------  
  BackendPort:
    Type: Number
    Default: 4567  
  BackendHealthCheckIntervalSeconds:
    Type: Number
    Default: 15
  BackendHealthCheckPath: 
    Type: String
    Default: "/api/health-check"
  BackendHealthCheckPort: 
    Type: String
    Default: 80
  BackendHealthCheckProtocol: 
    Type: String
    Default: HTTP
  BackendHealthCheckTimeoutSeconds: 
    Type: Number
    Default: 5
  BackendHealthyThresholdCount: 
    Type: Number
    Default: 2
  BackendUnhealthyThresholdCount: 
    Type: Number
    Default: 2
```

You may also note that above for our target groups we haven't fully implemented the `VpcId` property. We need to import the value of this from our networking `template.yaml` via a cross-stack reference. We do this through the use of the `Fn::ImportValue` function. The `Fn::ImportValue` function returns the value of an output exported by another stack. In our case, an export from our networking stack. We begin by passing the stack as a parameter.

```yaml
Parameters:
  NetworkingStack:
    Type: String  
    Description: This is our base layer of networking components e.g. VPC, Subnets
    Default: CrdNet
```

We then add the `Fn::ImportValue` function as the value of our `VpcId` property.

```yaml
      VpcId: 
        Fn::ImportValue:
          !Sub ${NetworkingStack}VpcId    
```

This is added for both the `FrontendTG` and `BackendTG` target groups. We're also using the `!Sub` function to substitute the `NetworkingStack` variable into the string. 

Since we added the parameters to allow cross stack references to our networking layer, we're now prepared to finish implementing the `Subnets` property we left blank earlier in our ALB. Andrew notes this is tricky, because they come in as a string, but we're going to need to break them down into an array. To do this, we're going to use the `Fn::Split` function. This function splits a string into a list of string values, so we can select an element from the resulting string list. Here's a further breakdown of that syntax: 

`Fn::Split: [delimiter, source string]`

```yaml
  ALB:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-elasticloadbalancingv2-loadbalancer.html
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub "${AWS::StackName}ALB"
      Type: application
      IpAddressType: ipv4
      # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-elasticloadbalancingv2-loadbalancer-loadbalancerattributes.html
      Scheme: internet-facing
      SecurityGroups: 
        - !Ref ALBSG
      Subnets: !Split [",", !ImportValue { "Fn::Sub": "${NetworkingStack}VpcId" }]
```

We are using the `Fn::Split` function (seen in short form here). You can see that our delimiter is a "," , with the source string using the `Fn::ImportValue` function we used above. Andrew implemented his a bit differently, but I believe I was running into indentation problems, and instead implemented it as one line, as seen above. Andrew's looked like this: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/df562946-7559-4c25-b684-03fe1d345069)

In reviewing our template prior to deploying, it's noted that our original naming for our networking stack was just `Cruddur`, which will not work for the additional layers we're going to be implementing. We must go back and rename it, setting a naming convention for future layers. We do this by going back to our `networking-deploy` script.

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails
CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/networking/template.yaml"
cfn-lint $CFN_PATH 

aws cloudformation deploy \
    --stack-name "CrdNet" \
    --s3-bucket $CFN_BUCKET \
    --template-file $CFN_PATH \
    --no-execute-changeset \
    --tags group="cruddur-networking" \
    --capabilities CAPABILITY_NAMED_IAM
```

Then we update `cluster-deploy`.

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails
CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/networking/template.yaml"
cfn-lint $CFN_PATH 

aws cloudformation deploy \
    --stack-name "CrdCluster" \
    --s3-bucket $CFN_BUCKET \
    --template-file $CFN_PATH \
    --no-execute-changeset \
    --tags group="cruddur-cluster" \
    --capabilities CAPABILITY_NAMED_IAM
```

To implement this change, we're going to have to tear down our existing network stack. We head back over to CloudFormation, and delete the `Cruddur` stack.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/7ac3066f-7b48-4b14-b6ec-ce54925cb203)

Andrew mentions we're also using the `Cruddur` name for our existing AWS resources as well, which we may run into conflicts about with future CFN templates. To circumvent this, we delete our existing AWS resources including frontend and backend services in ECS, Fargate cluster in ECS, ALB, target groups, Namespace from Cloud Map.

We are now ready to redeploy our network stack. We run `networking-deploy`, then head over to CloudFormation.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/72421a43-34d3-4c0b-99cb-b34ea38fc211)

We execute the changeset from CloudFormation, and while we're waiting come to find that we didn't update the value imported for our `Subnets` property of our ALB. To fix this, we have to go back over to our networking `template.yaml` and make sure of the name of the property being exported for `SubnetIds`.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/5ebfc2a0-bfb2-4c22-9e95-6b317a5e8165)

It's just `SubnetIds`, so we fix this in our cluster template. 

```yaml
      Subnets: !Split [",", !ImportValue { "Fn::Sub": "${NetworkingStack}SubnetIds" }]
```

We go back to CloudFormation again and check on our networking stack:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/6721810e-831a-4f77-bfa0-d5b12c806cb8)

With the stack created successfully, we check our Outputs, and decide we want to add the stack name to our exports. To do this, we use the `!Sub` function to add a pseudo parameter of the `StackName` to each output from our networking `template.yaml`. In the example shown below, we're updating the `VpcId` property's output:

```yaml
Outputs:
  VpcId:
    Value: !Ref VPC
    Export:
      Name: !Sub "${AWS::StackName}VpcId"
```

We again tear down our networking stack from CloudFormation, then start the cycle all over again: ran `networking-deploy` script and executed changeset from CFN. Our networking stack re-deploys without any issue, and when we check the Outputs again, they're now updated to include the `StackName` pseudo parameter. 

![1 47 51 into CFN Cluster Layer added stackname to outputs](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/2115c3ea-170d-4103-b8f1-54b622222218)

We're now ready to test our cluster stack's deployment. We run `cluster-deploy` from our terminal. We receive an error from `cfn-lint`:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/1df98404-26ff-48af-b1af-b71922c19550)

We're receiving an error because our `CertificateArn` does not have a value. For this, we're wanting to bring in an external value. To do this, we're going to use the library that Andrew created, `cfn-toml`. This will allow us to pull in external parameters as variables within our deploy scripts, then pass them during creation from our CFN templates. These values are normally hardcoded into the script/command to deploy the CFN template, but with Andrew's library this won't be necessary. 

Andrew directs us to his public repo for `cfn-toml` here: https://github.com/teacherseat/cfn-toml/tree/main and we walk through how to use it. We begin by installing `cfn-toml` through the CLI:

![1 43 into Week 10-11 CFN Toml Part 1 install gem](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/420e0267-1071-4344-92bd-6c75d062ae5d)

Then we add this to our `.gitpod.yml` so it's available to us readily from our workspace whenever we launch it. 

![2 14 into Week 10-11 CFN Toml Part 1 adding gem install cfn-toml to gitpodyml](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/f388d8cf-fcd6-464a-8135-7737b1a57bfc)

From here, we must define that `cfn-toml` file. In our `./aws/cfn/cluster` directory, we create `config.toml` and `config.toml.example` to show how to use it. 

Here's `config.toml.example`:

```toml
[deploy]
bucket = ''
region = ''
stack_name = ''

[parameters]
CertificateArn = ''
```

This gives us a point of reference for how to define our parameters in `config.toml`:

```toml
[deploy]
bucket = 'jh-cfn-artifacts'
region = 'us-east-1'
stack_name = 'CrdCluster'

[parameters]
CertificateArn = 'arn:aws:acm:us-east-1:554621479919:certificate/9e966975-36c4-4808-ad6a-d20172eef714'
NetworkingStack = 'CrdNet'
```

We now have to update our `cluster-deploy` script to implement these changes as well:

```sh
set -e #stop the execution of the script if it fails

CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/cluster/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/cluster/config.toml"

cfn-lint $CFN_PATH 

BUCKET=$(cfn-toml key deploy.bucket -t $CONFIG_PATH)
REGION=$(cfn-toml key deploy.region -t $CONFIG_PATH)
STACK_NAME=$(cfn-toml key deploy.stack_name -t $CONFIG_PATH)
PARAMETERS=$(cfn-toml params v2 -t $CONFIG_PATH)

aws cloudformation deploy \
    --stack-name "CrdCluster" \
    --s3-bucket $BUCKET \
    --region $REGION \
    --template-file $CFN_PATH \
    --no-execute-changeset \
    --tags group="cruddur-cluster" \
    --parameter-overrides $PARAMETERS \
    --capabilities CAPABILITY_NAMED_IAM
```

First, you can see we've updated the path for our `CONFIG_PATH` variable to point to our `config.toml` file. 

```sh
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/cluster/config.toml"
```

Then, `cfn-toml` uses these lines to read the values from `config.toml`:

```sh
BUCKET=$(cfn-toml key deploy.bucket -t $CONFIG_PATH)
REGION=$(cfn-toml key deploy.region -t $CONFIG_PATH)
STACK_NAME=$(cfn-toml key deploy.stack_name -t $CONFIG_PATH)
PARAMETERS=$(cfn-toml params v2 -t $CONFIG_PATH)
```

It retrieves the values for `deploy.bucket`, `deploy.region`, `deploy.stack_name`, and `params` and assigns them to the variables `BUCKET`, `REGION`, `STACK_NAME`, and `PARAMETERS`, respectively. We then pass these variables in our CFN deploy command:

```sh
aws cloudformation deploy \
    --stack-name "CrdCluster" \
    --s3-bucket $BUCKET \
    --region $REGION \
    --template-file $CFN_PATH \
    --no-execute-changeset \
    --tags group="cruddur-cluster" \
    --parameter-overrides $PARAMETERS \
    --capabilities CAPABILITY_NAMED_IAM
```

We run our `cluster-deploy` script just to make sure `cfn-toml` is working, and the changeset is created successfully. However, we're not wanting to execute the changeset yet as there's more alterations to be made, so instead we delete the `CrdCluster` stack from CloudFormation, while it's in the `REVIEW_IN_PROGRESS` state. 

![4 15 into Week 10-11 CFN Toml Part 2 cluster deploy works but we delete the stack without executing change set](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/325d4f4f-8c0b-4322-a37a-dd9d4153841d)

Knowing `cfn-toml` is working, we decide we want to implement this for our networking stack as well, so we tear this stack down from CloudFormation as well. Then we head back to our workspace and add a `config.toml` file to our `./aws/cfn/networking` directory, filling it in as we go: 

```toml
[deploy]
bucket = 'jh-cfn-artifacts'
region = 'us-east-1'
stack_name = 'CrdNet'
```

Note, there's no external parameters we're needing here, we're just passing our `bucket`, `region`, and `stack_name` variables for use in the `networking-deploy` script. Speaking of which, we now update that: 

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/networking/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/networking/config.toml"

cfn-lint $CFN_PATH

BUCKET=$(cfn-toml key deploy.bucket -t $CONFIG_PATH)
REGION=$(cfn-toml key deploy.region -t $CONFIG_PATH)
STACK_NAME=$(cfn-toml key deploy.stack_name -t $CONFIG_PATH)

aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --s3-bucket $BUCKET \
    --region $REGION \
    --template-file $CFN_PATH \
    --no-execute-changeset \
    --tags group="cruddur-networking" \
    --capabilities CAPABILITY_NAMED_IAM
```

You'll notice since there's no parameters to pass in the networking `config.toml`, we remove the `PARAMETERS` variable completely, along with the command for `--parameter-overrides`. If we left this, it would give us an error because there's no parameters to pass, as seen below: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/a82bef6f-8111-4f32-adad-2db1d4e766c1)

We have also updated the `CONFIG_PATH` variable to the correct path for our networking `config.toml` file. 

We re-deploy, running `networking-deploy` from the terminal, execute the changeset, and it creates successfully. We try `cluster-deploy` next. The changeset is created, but when we execute it from CloudFormation, it fails.

![12 18 into Week 10-11 CFN Toml Part 2 security group is not valid](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/d1faf435-1b51-4404-9742-ef4451d81df0)

We head over to CloudTrail in AWS to check on this error and find that the error occurred during the `CreateLoadBalancer` event:

![2 29 into Week 10-11 - CFN Cluster Layer FInish ValidationException in CloudTrail Event History](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/f5f2f526-911d-43b6-b3dc-816f463274b6)

We head back over to the cluster `template.yaml` and view the `SecurityGroups` property of our ALB. Everything appears correct in the code, so our attention is on the value being passed to `SecurityGroups` instead. 

```yaml
      SecurityGroups: 
        - !Ref ALBSG
      Subnets: !Split [",", !ImportValue { "Fn::Sub": "${NetworkingStack}SubnetIds" }]
```

After consulting AWS documentation, we find that the return value for the `!Ref` function should return us the logical ID of the resource. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/1654db0f-a869-4f02-a0ac-b890619dad31)

That being said, for Security Groups, we need to pass the Group ID instead. Andrew had a bit of confusion on this, but I asked ChatGPT to clarify the difference.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/cd59e380-0c6d-4fc5-be37-84192dc83158)

The example ChatGPT used for Group ID clarifies this: "in security groups, a group ID is used to uniquely identify a security group within a VPC. The group ID is specific to the security group resource and is different from the logical ID assigned by CloudFormation."

Since we're needing the Group ID, we must use the `Fn::GetAtt` function, specifying the `GroupId` attribute. 

We delete the cluster stack from CloudFormation, then go back to our workspace and implement the change suggested by AWS documentation:

```yaml
      SecurityGroups: 
        - !GetAtt ALBSG.GroupId
```

We again deploy our changeset to CloudFormation. A new error is returned.

![6 32 into Week 10-11 - CFN Cluster Layer Finish a load balancer cannot be attached to multiple subnets in the same AZ](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/3c0c979f-4d15-4862-92e6-03a10a51fab2)

There's something wrong with the configuration in our networking layer again. We review the Outputs of our networking stack from CloudFormation: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/f1ffa113-03d2-4b62-8b17-14b3dc77bae9)

We're outputting all of our subnets, both private and public from our networking stack, then importing every single one into the cluster. We don't need to do this.  We only need our private subnets. We decide to go back to the `Outputs` section of our networking `template.yaml` and export the private and public subnets separately. 

```yaml
  PublicSubnetIds: 
    Value: !Join 
      - "," 
      - - !Ref SubnetPub1 
        - !Ref SubnetPub2 
        - !Ref SubnetPub3
    Export: 
      Name: !Sub "${AWS::StackName}PublicSubnetIds"          
  PrivateSubnetIds: 
    Value: !Join 
      - "," 
      - - !Ref SubnetPriv1
        - !Ref SubnetPriv2
        - !Ref SubnetPriv3
    Export: 
      Name: !Sub "${AWS::StackName}PrivateSubnetIds"
```

We run `networking-deploy` again, then execute the changeset from CFN. This changeset completes quickly, as it's not changing anything, just adjusting the outputs:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/862a4b7f-f50e-4929-8a45-2f342bc7ec9f)

Back in our cluster `template.yaml` now, we adjust the value imported for our `Subnets` property.

```yaml
      Subnets: !Split [",", !ImportValue { "Fn::Sub": "${NetworkingStack}PublicSubnetIds" }]
```

We run `cluster-deploy`, execute the changeset for our cluster layer from CloudFormation, then view the error returned: 

![12 30 into Week 10-11 - CFN Cluster Layer Finish security group does not belong to VPC](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/23d00e81-1786-4c60-8752-ad29f5f05541)

To fix this, we go back into our cluster `template.yaml` and view the `ALBSG` security group we created previously. We're missing a property for `VpcId`. We add this, importing the value of `VpcId` from our networking stack.

```yaml
      VpcId: 
        Fn::ImportValue:
          !Sub ${NetworkingStack}VpcId 
```

We delete the cluster stack that did not complete successfully in CloudFormation, then run our `cluster-deploy` script once again. We execute this changeset from CloudFormation, and the stack deploys successfully. You can see the Description we set displayed in the Overview of the stack from CloudFormation.

![17 53 into Week 10-11 - CFN Cluster Layer Finish CrdCluster Overview](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/9212e652-b4ef-4713-a238-c81001fcc601)

This should complete the cluster layer, so we're now able to move onto our service layer. Before proceeding here, Andrew makes mention that he's deciding how we want to go about this. 

## Service Layer

The service layer could include task definitions, but we may want those in a separate CloudFormation template, as they could go through rapid iterations. Just as a general practice, at least from what I've studied on this, it can be beneficial to make a separate CFN template for task definitions and the service, as there's benefits in terms of modularity, reusability, and flexibility. We decide to take a look at our current task definition file for the the backend service. We decide to use it as a point of reference and include the task definitions in the same CFN template as the service.

We begin by making a new folder in `./aws/cfn` named `service`, then populate the folder with several new files: `config.toml`, `config.toml.example`, and `template.yaml`. From our `./bin/cfn` directory, we create a new script file named `service-deploy`. Starting off in our service `template.yaml`, we begin fleshing it out, just the same as our previous CFN templates. 

```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: | 
  Task Definition
  Fargate Service
  Execution Role
  Task Role
  
Parameters: 
  NetworkingStack:
    Type: String  
    Description: This is our base layer of networking components e.g. VPC, Subnets
    Default: CrdNet
  ClusterStack:
    Type: String  
    Description: This is our cluster layer e.g. ECS Cluster
    Default: CrdCluster
    
Resources: 
  ServiceSG:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html
    Type: AWS::EC2::SecurityGroup
    Properties: 
      GroupName: !Sub "${AWS::StackName}AlbSG"
      GroupDescription: Public Facing SG for our Cruddur ALB
      VpcId: 
        Fn::ImportValue:
          !Sub ${NetworkingStack}VpcId 
      SecurityGroupIngress:
        - IpProtocol: tcp
          SourceSecurityGroupId:
            Fn::ImportValue:
              !Sub ${ClusterStack}ALBSecurityGroupId       
          FromPort: 80
          ToPort: 80
          CidrIp: '0.0.0.0/0'
          Description: ALB HTTP

```

You can see from above that we already are importing the value of the `VpcId` and the `ALBSecurityGroupId` from our networking layer and cluster layer respectively, so we added these stacks as parameters. We're using the networking layer's `VpcId`, so we must import the value as the the value of `VpcId` here. Under `SecurityGroupIngress`, we are defining the inbound rules of the security group, allowing incoming traffic from the cluster layer's security group. 

We already know we're exporting the value of `VpcId` from our networking `template.yaml`. Since the cluster stack is referenced as a parameter here and we're importing the value as well, we must set this as an output from our cluster `template.yaml` and export it:

```yaml
Outputs:  
  ALBSecurityGroupId:
    Value: !GetAtt ALBSG.GroupId
    Export:
      Name: !Sub "${AWS::StackName}ALBSecurityGroupId"
```

We next begin working on the service itself in our `template.yaml` file. We look up the documentation through AWS, and are immediately hit with this "Important" disclaimer:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/f01d5330-b568-4ef6-a223-08107d0127f8)

What this message indicates is, in AWS CloudFormation, when you update a stack, any changes to a resource's properties that require replacement (meaning the resource must be recreated) can result in a failure if there is at least one AWS Service Discovery service (ServiceConnectService) configured for the ECS service. For further clarification, I asked ChatGPT the reason for this:

"The reason for this is related to the uniqueness of service names within the AWS Service Discovery namespace. Each AWS Service Discovery service, which provides service discovery capabilities for ECS services, must have a unique name within the namespace. When AWS CloudFormation performs a stack update, it follows a sequence where it creates the replacement service first before deleting the original service.

However, if there is at least one AWS Service Discovery service associated with the ECS service, the replacement service cannot have the same name as the original service due to the requirement for unique service names. This creates a conflict because AWS CloudFormation tries to create the replacement service with the same name, leading to a stack update failure."

Andrew lets us know this is important information to keep in mind moving on. We continue on, creating our `FargateService`. There's a lot of properties to define here, so we start out just adding properties we know we're going to need. 

```yaml
  FargateService:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ecs-service.html
    Type: AWS::ECS::Service
    Properties: 
      Cluster: 
      DeploymentConfiguration:
      DeploymentController: 
      DesiredCount:
      EnableECSManagedTags: true
      EnableExecuteCommand: true
      HealthCheckGracePeriodSeconds:
      LaunchType: FARGATE
      LoadBalancers: 
        -
      NetworkConfiguration:
      PlatformVersion: LATEST
      PropagateTags: TASK_DEFINITION
      Role:   
      ServiceConnectConfiguration:
      ServiceName:
```

At this point, we look at our existing `deploy` script for the backend service and find the task definition file it references to create the service. We navigate to this task definition file and ask ChatGPT to convert the file into a CFN template. We use this output to begin populating the properties for `FargateService` in our service `template.yaml`. 

```yaml
  FargateService:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ecs-service.html
    Type: AWS::ECS::Service
    Properties: 
      Cluster: 
      DeploymentConfiguration:
      DeploymentController: 
      DesiredCount:
      EnableECSManagedTags: true
      EnableExecuteCommand: true
      HealthCheckGracePeriodSeconds:
      LaunchType: FARGATE
      LoadBalancers:
        - TargetGroupArn: arn:aws:elasticloadbalancing:us-east-1:554621479919:targetgroup/cruddur-backend-flask-tg/894e612b59521c2c
          ContainerName: backend-flask
          ContainerPort: !Ref ContainerPort
      NetworkConfiguration:
        AwsvpcConfiguration:
          AssignPublicIp: ENABLED
          SecurityGroups:
            - !GetAtt ServiceSG.GroupId
          Subnets: !Split [",", !ImportValue { "Fn::Sub": "${NetworkingStack}PublicSubnetIds" }]
      PlatformVersion: LATEST
      PropagateTags: SERVICE
      ServiceRegistries:
        - RegistryArn: !Sub 'arn:aws:servicediscovery:${AWS::Region}:${AWS::AccountId}:service/srv-cruddur-backend-flask'
          Port: !Ref ContainerPort
          ContainerName: backend-flask
          ContainerPort: !Ref ContainerPort
      ServiceName: !Ref ServiceName
      TaskDefinition: !Ref TaskFamily
```

We add a parameter to the `template.yaml` file for `ContainerPort`:

```yaml
Parameters:
  NetworkingStack:
    Type: String  
    Description: This is our base layer of networking components e.g. VPC, Subnets
    Default: CrdNet
  ClusterStack:
    Type: String  
    Description: This is our cluster layer e.g. ECS Cluster
    Default: CrdCluster
  ContainerPort:
    Type: Number
    Default: 4567
```

We repeat the steps above, this time asking ChatGPT to convert the `backend-flask` task definition file to a CFN template. We again copy/paste the output to our workspace for our `TaskDefinition`, editing it as we go:

```yaml
  TaskDefinition:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ecs-taskdefinition.html
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: !Ref TaskFamily
      ExecutionRoleArn: arn:aws:iam::554621479919:role/CruddurServiceExecutionRole
      TaskRoleArn: arn:aws:iam::554621479919:role/CruddurTaskRole
      NetworkMode: awsvpc
      Cpu: !Ref ServiceCpu
      Memory: !Ref ServiceMemory
      RequiresCompatibilities:
        - FARGATE
      ContainerDefinitions:
        - Name: xray
          Image: public.ecr.aws/xray/aws-xray-daemon
          Essential: true
          User: "1337"
          PortMappings:
            - Name: xray
              ContainerPort: 2000
              Protocol: udp
        - Name: backend-flask
          Image: !Ref EcrImage
          Essential: true
          HealthCheck:
            Command:
              - CMD-SHELL
              - python /backend-flask/bin/health-check
            Interval: 30
            Timeout: 5
            Retries: 3
            StartPeriod: 60
          PortMappings:
            - Name: !Ref ContainerName
              ContainerPort: !Ref ContainerPort
              Protocol: tcp
              AppProtocol: http
          LogConfiguration:
            LogDriver: awslogs
            Options:
              awslogs-group: cruddur
              awslogs-region: ${AWS::Region}
              awslogs-stream-prefix: !Ref ServiceName
          Environment:
            - Name: OTEL_SERVICE_NAME
              Value: !Ref EnvOtelServiceName
            - Name: OTEL_EXPORTER_OTLP_ENDPOINT
              Value: !Ref EnvOtelExporterOtlpEndpoint
            - Name: AWS_COGNITO_USER_POOL_ID
              Value: !Ref EnvAWSCognitoUserPoolId
            - Name: AWS_COGNITO_USER_POOL_CLIENT_ID
              Value: !Ref EnvCognitoUserPoolClientId
            - Name: FRONTEND_URL
              Value: !Ref EnvFrontendUrl
            - Name: BACKEND_URL
              Value: !Ref EnvBackendUrl
            - Name: AWS_DEFAULT_REGION
              Value: ${AWS::Region}
          Secrets:
            - Name: AWS_ACCESS_KEY_ID
              ValueFrom: !Ref SecretsAWSAccessKeyId
            - Name: AWS_SECRET_ACCESS_KEY
              ValueFrom: !Ref SecretsSecretAccessKey
            - Name: CONNECTION_URL
              ValueFrom: !Ref SecretsConnectionUrl
            - Name: ROLLBAR_ACCESS_TOKEN
              ValueFrom: !Ref SecretsRollbarAccessToken
            - Name: OTEL_EXPORTER_OTLP_HEADERS
              ValueFrom: !Ref SecretsOtelExporterOtlpHeaders
```

In this code snippet, we're defining our ECS task definition. We're specifying the properties and configuration of the task, along with container defintions, networking, resource allocation, logging, environment variables, and secrets. These values and configurations can be setup through click-ops using the AWS console as well.  

Lots of parameters added for these values listed here, so we add them in addition to `ContainerPort` from earlier to our `template.yaml`. 

```yaml
  ServiceCpu:
    Type: String
    Default: '256'
  ServiceMemory:
    Type: String
    Default: '512'
  ServiceName:
    Type: String
    Default: backend-flask
  ContainerName:
    Type: String
    Default: backend-flask
  TaskFamily: 
    Type: String
    Default: backend-flask
  EcrImage:
    Type: String
    Default: '554621479919.dkr.ecr.us-east-1.amazonaws.com/backend-flask'
  EnvOtelServiceName:
    Type: String
    Default: backend-flask
  EnvOtelExporterOtlpEndpoint:
    Type: String
    Default: 'https://api.honeycomb.io'
  EnvAWSCognitoUserPoolId:
    Type: String
    Default: 'us-east-1_N7WWGl3KC'
  EnvCognitoUserPoolClientId:
    Type: String
    Default: '575n8ecqc551iscnosab6e0un3'
  EnvFrontendUrl:
    Type: String
    Default: 'https://thejoshdev.com'
  EnvBackendUrl:
    Type: String
    Default: 'https://api.thejoshdev.com'
  SecretsAWSAccessKeyId:
    Type: String
    Default: 'arn:aws:ssm:us-east-1:554621479919:parameter/cruddur/backend-flask/AWS_ACCESS_KEY_ID' 
  SecretsSecretAccessKey:
    Type: String
    Default: 'arn:aws:ssm:us-east-1:554621479919:parameter/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY'
  SecretsConnectionUrl:
    Type: String
    Default: 'arn:aws:ssm:us-east-1:554621479919:parameter/cruddur/backend-flask/CONNECTION_URL'   
  SecretsRollbarAccessToken:
    Type: String
    Default: 'arn:aws:ssm:us-east-1:554621479919:parameter/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN'  
  SecretsOtelExporterOtlpHeaders:
    Type: String
    Default: 'arn:aws:ssm:us-east-1:554621479919:parameter/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS' 
```

You'll notice in our `TaskDefinition` defined in the service template above is hardcoding our values for `TaskRoleArn` and `ExecutionRoleArn` currently. That's because we haven't defined IAM roles in our service template yet. We begin by defining our execution policy for our execution role. We navigate to IAM in AWS to view our existing execution policy to reference:

```yaml
Resources:
  ExecutionPolicy:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-policy.html
    Type: AWS::IAM::Policy
    Properties:
      PolicyName: cruddur-execution-policy
      PolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Sid: VisualEditor0
            Effect: Allow
            Action:
              - ecr:GetAuthorizationToken
              - ecr:BatchCheckLayerAvailability
              - ecr:GetDownloadUrlForLayer
              - ecr:BatchGetImage
              - logs:CreateLogStream
              - logs:PutLogEvents
            Resource: "*"
          - Sid: VisualEditor1
            Effect: Allow
            Action:
              - ssm:GetParameters
              - ssm:GetParameter
            Resource: !Sub 'arn:aws:ssm:${AWS::Region}:${AWS::AccountId}:parameter/cruddur/${ServiceName}/*'        
```

In this policy, we're defining the actions allowed for various AWS resources and services. Here's what we're allowing access to: 

`ecr:GetAuthorizationToken`: Allows getting authorization tokens from Amazon Elastic Container Registry (ECR).

`ecr:BatchCheckLayerAvailability`: Allows batch checking the availability of Docker image layers in ECR.

`ecr:GetDownloadUrlForLayer`: Allows getting the download URL for a Docker image layer in ECR.

`ecr:BatchGetImage`: Allows batch getting Docker images from ECR.

`logs:CreateLogStream`: Allows creating log streams in Amazon CloudWatch Logs.

`logs:PutLogEvents`: Allows putting log events into Amazon CloudWatch Logs.

`ssm:GetParameters`: Allows getting parameters from AWS Systems Manager (SSM).

`ssm:GetParameter`: Allows getting a specific parameter from AWS Systems Manager (SSM).

We continue on, defining our role: 

```yaml
  ExecutionRole:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-role.html
    Type: AWS::IAM::Role
    Properties: 
      RoleName: 'CruddurServiceExecutionRole'
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: 'Allow'
            Principal:
              Service: 'ecs-tasks.amazonaws.com'
            Action: 'sts:AssumeRole'
      ManagedPolicyArns:
        - !Sub 'arn:aws:iam::${AWS::AccountId}:policy/${ExecutionPolicy}'
        - 'arn:aws:iam::aws:policy/CloudWatchLogsFullAccess'
```

In the IAM role we defined, we're allowing the ECS tasks service to assume the role. There's managed policies attached to grant access to specific permissions required for task execution, including the permissions defined in the referenced `ExecutionPolicy` parameter we defined above along with CloudWatch Logs access. 

We're now able to reference the role in our `TaskDefinition` we defined earlier in the service `template.yaml`.

```yaml
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: !Ref TaskFamily
      ExecutionRoleArn: !GetAtt ExecutionRole.Arn
      TaskRoleArn: !GetAtt TaskRole.Arn      
```

In the snippet above, we use the `!GetAtt` function to get the `Arn` attribute from the `ExecutionRole` property to define the value of `ExecutionRoleArn`. Although we haven't defined the `TaskRole` yet, we add the same for `TaskRoleArn`. 

We should now be able to define our `TaskRole`. We again go to IAM in AWS to reference the existing task role and begin implementing:

```yaml
  TaskRole:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-role.html
    Type: AWS::IAM::Role
    Properties: 
      RoleName: 'CruddurServiceTaskRole'
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:  
          - Effect: 'Allow'
            Principal:
              Service: 'ecs-tasks.amazonaws.com'
            Action: 'sts:AssumeRole' 
      ManagedPolicyArns:
        - !Sub 'arn:aws:iam::${AWS::AccountId}:policy/${TaskPolicy}'
        - 'arn:aws:iam::aws:policy/CloudWatchLogsFullAccess'
        - 'arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess'
```

Very much like our `ExecutionRole` property above, we're allowing the ECS tasks service to assume the role. We're attached managed policies to grant specific permissions for tasks. This time, we're giving permissions for SSM messages, CloudWatch Logs access, and AWS X-Ray Daemon write access.

Then we add the `TaskPolicy` to define the SSM message permissions:

```yaml
  TaskPolicy:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-policy.html
    Type: AWS::IAM::Policy
    Properties:
      PolicyName: cruddur-task-policy
      PolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Sid: VisualEditor0
            Effect: Allow
            Action:
              - ssmmessages:CreateControlChannel
              - ssmmessages:CreateDataChannel
              - ssmmessages:OpenControlChannel
              - ssmmessages:OpenDataChannel
            Resource: "*" 
```

Our service `template.yaml` looks to be good for now, so we move our attention to our `service-deploy` script. We begin by copying our existing `cluster-deploy` script and then editing it specific for the service layer instead: 

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/service/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/service/config.toml"

cfn-lint $CFN_PATH 

BUCKET=$(cfn-toml key deploy.bucket -t $CONFIG_PATH)
REGION=$(cfn-toml key deploy.region -t $CONFIG_PATH)
STACK_NAME=$(cfn-toml key deploy.stack_name -t $CONFIG_PATH)
PARAMETERS=$(cfn-toml params v2 -t $CONFIG_PATH)

aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --s3-bucket $BUCKET \
    --region $REGION \
    --template-file $CFN_PATH \
    --no-execute-changeset \
    --tags group="cruddur-backend-flask" \
    --parameter-overrides $PARAMETERS \    
    --capabilities CAPABILITY_NAMED_IAM
```

We have adjusted the pathing for our `CFN_PATH` and `CONFIG_PATH` variables to reflect the service layer pathings. We also implement our `config.toml` file for the service layer as well: 

```toml
[deploy]
bucket = 'jh-cfn-artifacts'
region = 'us-east-1'
stack_name = 'CrdSrvBackendFlask'
```

After running our `chmod u+x ./bin/cfn/service-deploy` to make our script executable, we run the `service-deploy` script. We begin working through a myriad of errors and warnings from `cfn-lint`. First, we realize we didn't define a value for the `Cluster` property of the `FargateService`. We import the value from our cluster stack.

```yaml
  FargateService:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ecs-service.html
    Type: AWS::ECS::Service
    Properties: 
      Cluster: 
        Fn::ImportValue:
          !Sub "${ClusterStack}ClusterName"
```

Since we imported the value of the cluster name from our cluster stack, we have to go back to our cluster `template.yaml` to export it as well.

```yaml
Outputs:
  ClusterName:
    Value: !Ref FargateCluster
    Export:
      Name: !Sub "${AWS::StackName}ClusterName"  
```

With this change, before our service layer can be deployed, we have to redeploy the cluster layer for that Output. We run our `cluster-deploy` script again, then execute the changeset created from CloudFormation. When it completes, we have a status of `UPDATE_COMPLETE`, so we check out Outputs to make sure. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/2551b866-1ce4-4c8f-940d-82f669b96251)

We now have the `ClusterName` as an Output. 

We continue working through the errors for our service `template.yaml`:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/eaa60d4f-a9c3-41d3-8828-2cee0f34fa32)

We remove the `CidrIp` property from our `ServiceSG` as we no longer need it since we defined the value of `SourceSecurityGroupId` by importing the value from out cluster layer's ALB security group. 

```yaml
Resources:
  ServiceSG:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html
    Type: AWS::EC2::SecurityGroup
    Properties: 
      GroupName: !Sub "${AWS::StackName}AlbSG"
      GroupDescription: Public Facing SG for our Cruddur ALB
      VpcId: 
        Fn::ImportValue:
          !Sub ${NetworkingStack}VpcId 
      SecurityGroupIngress:
        - IpProtocol: tcp
          SourceSecurityGroupId:
            Fn::ImportValue:
              !Sub ${ClusterStack}ALBSecurityGroupId       
          FromPort: 80
          ToPort: 80
          Description: ALB HTTP
```

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/e711d2aa-4efe-4467-9c53-6d019cfc5505)

There's also several missing values for properties of our `FargateService` that we need to define as well. We're not going to use `DeploymentConfiguration`, so we remove the property entirely. We then define values for `DeploymentController` and `DesiredCount`. 

```yaml
      DeploymentController: 
        Type: ECS
      DesiredCount: 1
```

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/722f5876-f41b-4150-9371-45944fd27e95)

We update the `HealthCheckGracePeriodSeconds` property of the `FargateService` to 0. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/3b1132ba-185b-4583-b8c5-2362b461ffb5)

Our `TaskDefinition` is using embedded parameters outside of a function. We edit this to correct it for `awslogs-region` and the value of an env var defined under `Environment`.

```yaml
              awslogs-region: !Ref AWS::Region
```

```yaml
            - Name: AWS_DEFAULT_REGION
              Value: !Ref AWS::Region
```

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/9356f0f3-04ab-4187-9332-3d83473c3050)

To fix these errors, we decide to alter our existing policies to be inline with our roles. First the task role: 

```yaml
  TaskRole:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-role.html
    Type: AWS::IAM::Role
    Properties: 
      RoleName: 'CruddurServiceTaskRole'
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: 'Allow'
            Principal:
              Service: 'ecs-tasks.amazonaws.com'
            Action: 'sts:AssumeRole'
      Policies:
        - PolicyName: 'cruddur-task-policy'
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Sid: VisualEditor0
                Effect: Allow
                Action:
                  - ssmmessages:CreateControlChannel
                  - ssmmessages:CreateDataChannel
                  - ssmmessages:OpenControlChannel
                  - ssmmessages:OpenDataChannel
                Resource: "*"              
      ManagedPolicyArns:
        - !Sub 'arn:aws:iam::${AWS::AccountId}:policy/${TaskPolicy}'
        - 'arn:aws:iam::aws:policy/CloudWatchLogsFullAccess'
        - 'arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess'
```

Then, the execution role: 

```yaml
  ExecutionRole:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-role.html
    Type: AWS::IAM::Role
    Properties: 
      RoleName: 'CruddurServiceExecutionRole'
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: 'Allow'
            Principal:
              Service: 'ecs-tasks.amazonaws.com'
            Action: 'sts:AssumeRole'
      Policies:
        - PolicyName: 'cruddur-execution-policy'
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Sid: VisualEditor0
                Effect: Allow
                Action:
                  - ecr:GetAuthorizationToken
                  - ecr:BatchCheckLayerAvailability
                  - ecr:GetDownloadUrlForLayer
                  - ecr:BatchGetImage
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                Resource: "*"
              - Sid: VisualEditor1
                Effect: Allow
                Action:
                  - ssm:GetParameters
                  - ssm:GetParameter
                Resource: !Sub 'arn:aws:ssm:${AWS::Region}:${AWS::AccountId}:parameter/cruddur/${ServiceName}/*'            
      ManagedPolicyArns:
        - !Sub 'arn:aws:iam::${AWS::AccountId}:policy/${ExecutionPolicy}'
        - 'arn:aws:iam::aws:policy/CloudWatchLogsFullAccess'
```

With these changes, we again try to run our `service-deploy` script:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/ec8a142e-1f35-484b-b676-292e99bf7433)

This error is coming from `cfn-toml`. We're not passing any parameters in our `config.toml` file, so we comment out the `PARAMETERS` variable pathing, and the command from the `service-deploy` script as well: 

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/service/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/service/config.toml"

cfn-lint $CFN_PATH 

BUCKET=$(cfn-toml key deploy.bucket -t $CONFIG_PATH)
REGION=$(cfn-toml key deploy.region -t $CONFIG_PATH)
STACK_NAME=$(cfn-toml key deploy.stack_name -t $CONFIG_PATH)
#PARAMETERS=$(cfn-toml params v2 -t $CONFIG_PATH)

aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --s3-bucket $BUCKET \
    --region $REGION \
    --template-file $CFN_PATH \
    --no-execute-changeset \
    --tags group="cruddur-backend-flask" \
    --capabilities CAPABILITY_NAMED_IAM
    #--parameter-overrides $PARAMETERS \
```

With this error fixed, we again run `service-deploy`. This time, a changeset is created, so we head over to CloudFormation and execute it. When we check the Events tab of CloudFormation, we have a status of `CREATE_FAILED`.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/484025cc-3a8f-4fc2-93a1-065dbf44d339)

We knew this would happen, as the IAM role we're trying to create already exists with that same name. We delete the stack from CFN, then head over to IAM and delete the existing `CruddurServiceExecutionRole` and `CruddurTaskRole`. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/d5109d6f-cdc3-4f68-bea5-6576f8708f07)

We run `service-deploy` again, then execute the changeset once more. This time, our create fails again, but for a different reason:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/268b9882-22a0-4b6a-9798-6a575dd03a04)

We go back to our `template.yaml` and find that we're still referencing the old policies we setup prior to making them inline for our task and execution roles. We remove these references:

For our task role:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/95edfd3a-9071-4f84-8426-7cc981708ccf)


For our execution role: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/9aaeeb8a-332a-4afa-9789-fb8515be3744)

We move back to CloudFormation, delete the service stack since it hasn't successfully deployed yet, then run our `service-deploy` script once more. We then execute the changeset from CloudFormation again: 

![End of Week 10-11 CFN Service Layer target group does not exist](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/c66af6b8-49c7-4d88-83d3-be4bacb196c2)

This is likely due to the value of the `TargetGroupArn` property of our `LoadBalancer` under `FargateService` is still a hard-coded value pulled from our existing task definition file earlier. We head back to our workspace and find this to be the case. 

To fix the issue, we open our cluster `template.yaml` and add a couple of Outputs, as we're going to need target group ARN's for both our frontend and backend services. 

```yaml
  FrontendTGArn:
    Value: !Ref FrontendTG
    Export: 
      Name: !Sub "${AWS::StackName}FrontendTGArn"
  BackendTGArn:
    Value: !Ref BackendTG
    Export: 
      Name: !Sub "${AWS::StackName}BackendTGArn"
```

Just so these outputs are available to us for our service layer, we must run `cluster-deploy` again and execute the changeset from CloudFormation. Since there's no infrastructure changes, the changeset completes successfully almost instantly. When we check our Outputs, we now have a `FrontendTGArn` and `BackendTGArn` listed for our cluster layer.  

Now we can cross stack reference these Outputs in our service `template.yaml`. We fix the `TargetGroupArn` property for our `FargateService` load balancer. 

```yaml
      LoadBalancers:
        - TargetGroupArn:
            Fn::ImportValue:
              !Sub "${ClusterStack}BackendTGArn"  
```

With these changes, we delete the service stack from CFN as it never successfully deployed, then run our `service-deploy` script again. In CloudFormation, we execute the changeset: 

![6 35 into CFN ECS Fargate Service Debugging invalid request provided createservice error](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/c0a074d4-589a-4308-9734-cf3be828ddb5)

We go ahead and tear down the stack since it didn't deploy, then head back over to our workspace and view our cluster `template.yaml`, specifically looking for our target group for the backend service. We're missing the `TargetType` property for our target groups.  We consult the AWS documentation on this:

![8 04 into CFN ECS Fargate Service Debugging targettypeinstaceisdefault](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/8ca4d5c9-511e-43f9-a439-af3a2e6425ac)

Since this value wasn't being set by us, for an application load balancer target group such as this, the default value of `TargetType` was set to `instance`, meaning the target group would target EC2 instances instead of our Fargate Service. We add this property for both the frontend and backend target groups, specifying `ip` as the value instead.

```yaml
      TargetType: ip
```

We again want to update our cluster layer, so we again run the `cluster-deploy` script, execute the changeset from CFN and wait for the results:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/9ae6ac4a-2f4f-479f-bd22-2352605b26ef)

We're getting errors that the target groups already exist and won't update. After a bit of research we find this is likely due to the name of the target group being defined. Since we provided the name in the template, CFN is erroring when trying to update because the name already exists. CloudFormation associates the logical ID with the resource. If the logical ID remains unchanged, CFN should recognize the resource is already created and update it. Since the name is defined already, AWS is basically telling us there's nothing to update. 

Andrew said this is one of those cases where it's better not to provide our own name for the resource. We comment out the line of code defining the name of our target groups:

```yaml
      #Name: !Sub "${AWS::StackName}FrontendTG"
```

```yaml
      #Name: !Sub "${AWS::StackName}BackendTG"
```

Instead, we decide to implement tags.

```yaml
      Tags: 
        - Key: target-group-name
          Value: frontend  
```

```yaml
      Tags: 
        - Key: target-group-name
          Value: backend 
```

We again run the `cluster-deploy` script and execute the changeset from CloudFormation. The cluster stack shows `UPDATE_COMPLETE` status. Just to see the changes, we head over to EC2 in AWS to view our target groups and how they're now named: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/c40141b3-a20f-4107-8b40-08827a6fe8e8)

When we select the backend target group, we're able to see our tags are applied successfully:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/e1252d6b-96bc-4325-80e2-da3c5ae5e221)

We head back over to our workspace and attempt to deploy our service stack via the `service-deploy` script. Then we execute the changeset from CloudFormation again. We have another `CREATE_FAILED` status:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/cd051b2a-3018-49f1-8510-823d10c8bc2a)

We open CloudTrail through AWS, and take a look at the `CreateService` action, as it's the last action that ran prior to the rollback.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/897efdcf-5c07-43a0-b765-c41ffbb6858d)

Andrew believes the issue is with the Service Connect for the backend service. We go back to our workspace and open our `./aws/json/service-backend-flask.json` file to view the existing configuration:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/74cfc797-2d7a-4e11-9449-55273ad3b1b9)

We compare this to the service `template.yaml` and how it was implemented. Our existing code makes use of the `ServiceRegistries` property for the `FargateService`. It has a `RegistryArn` property defined, so that would mean the service already exists, which it shouldn't. We're not even using the `ServiceConnectConfiguration` property. We comment out our `ServiceRegistries` property and instead define `ServiceConnectConfiguration`:

```yaml
      ServiceConnectConfiguration:
          Enabled: true
          Namespace: "cruddur"
          # TODO - If you want to log
          # LogConfiguration:
          Services: 
            - DiscoveryName: "backend-flask"
              PortName: "backend-flask"
              ClientAliases:
                - Port: 4567

      #ServiceRegistries:
      #  - RegistryArn: !Sub 'arn:aws:servicediscovery:${AWS::Region}:${AWS::AccountId}:service/srv-cruddur-backend-flask'
      #    Port: !Ref ContainerPort
      #    ContainerName: backend-flask
      #    ContainerPort: !Ref ContainerPort
```

We again delete the existing service stack from CloudFormation, then run `service-deploy` and execute the changeset. After an extended period of time, we refresh the Events tab of CloudFormation, but the `FargateService` is still being created by CloudFormation. We decide to head over to ECS in AWS instead to check the service. We can see already there's tasks failing. We click into one to see what's going on:

![24 45 into CFN ECS Fargate Service Debugging taskfailedelbhealthcheck](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/0c234a58-1b0e-4784-ae0d-0269081f3c28)

Andrew believes this could be due to an issue with the health check on the container is so fast that it does not detect when the app fails and/or issues with the ports for the security group. We head over to the security group for the backend service in EC2 and edit the Inbound Rules, opening up the ports for all traffic, just for testing purposes. Our tasks are still failing at this point. We decide to adjust our health check settings for the target group in EC2. We head over there, and select the Health Check tab for our backend target group then edit it manually through the console:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/4a039a34-0fec-48a9-a311-e9c28955cded)

Tasks are still failing. We attempt to run the backend service from our `./bin/backend/deploy` script updating the values to our existing layer information, but this fails. We update the `HealthCheckGracePeriodSeconds` property of our `FargateService` in the service template to 100 seconds, redeploy the service stack, and this makes no change. Our tasks are still failing.

We're going to redeploy the service layer again, but prior to this, we are going to make sure to give access to the service security group for our database. We again access our service `template.yaml` and add an Output for the security group:

```yaml
Outputs: 
  ServiceSecurityGroupId:
    Value: !GetAtt ServiceSG.GroupId
    Export:
      Name: !Sub "${AWS::StackName}ServiceSecurityGroupId"
```

We deploy the service stack via `service-deploy` then execute the changeset. 

After several tasks fail through ECS from our backend service, we head over to RDS to access our existing database, then access the existing security group for it, and edit the inbound rules to try and grant access to our service security group. AWS is unable to find our service security group. Andrew believes he knows why this is. The existing database security group is setup in the default VPC through AWS. Our service is setup in a different one altogether. 

After many troubleshooting attempts, we find that the tasks are failing because of our existing PostGres database. The health check of the tasks are probably failing because the tasks are starting up while there's connection issues to the database as the service starts. The connection issue is because the database has no access to the service security group. Since we haven't setup our new database yet, this is going to continue to fail.  

We're going to have to leave the service layer in an uncompleted state for now, and move onto the RDS layer, then we can circle back and complete the service layer at that time. We go ahead and delete the service layer stack from CloudFormation. 

## Database (RDS) Layer

We begin the RDS layer by creating a new folder in the `./aws/cfn` directory named `db`. We create a new `template.yaml` in this folder as well. We begin as always, fleshing out the RDS template.

```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: |
  The primary Postgres RDS Database for the application
  - RDS Instance
  - Database Security Group
  - DBSubnetGroup
  
  Parameters:
  Resources:
#Outputs: 
#  ServiceSecurityGroupId:
#    Value: !GetAtt ServiceSG.GroupId
#    Export:
#      Name: !Sub "${AWS::StackName}ServiceSecurityGroupId"
```

Andrew notes that we want the security group from our service layer, but just in case we end up not needing it, we will comment it out for now. Next we bring in our RDS instance: 

```yaml
Resources:
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-rds-dbinstance.html
  Type: AWS::RDS::DBInstance
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html
  DeletionPolicy: 'Snapshot'
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatereplacepolicy.html
  UpdateReplacePolicy: 'Snapshot'
  Properties: 
    AllocatedStorage: '20'
    AllowMajorVersionUpgrade: true
    AllowMinorVersionUpgrade: true
    BackupRetentionPeriod: !Ref BackupRetentionPeriod
    DBInstanceClass: !Ref DBInstanceClass
```
You might notice some particular properties of the `Resources`. Let's break those down a bit here: 

`DeletionPolicy`: Specifies the deletion policy for the resource, which is set to 'Snapshot'. This means that when the resource is deleted, a final snapshot will be created before deletion.

`UpdateReplacePolicy`: Specifies the update/replace policy for the resource, which is set to 'Snapshot'. This means that when the resource is updated, it will be replaced with a new resource and a snapshot of the old resource will be created.

Let's break down the rest of the properties:

`AllocatedStorage`: This property specifies the amount of storage allocated for the RDS database instance. In this case, it is set to '20', indicating 20 gigabytes of storage. This keeps us in the free tier of AWS. 

`AllowMajorVersionUpgrade`: This property determines whether major version upgrades are allowed for the database engine. When set to `true`, it allows the RDS instance to be upgraded to a new major version when available.

`AllowMinorVersionUpgrade`: This property determines whether minor version upgrades are allowed for the database engine. When set to `true`, it allows the RDS instance to be upgraded to a new minor version when available.

`BackupRetentionPeriod`: This property specifies the number of days to retain automated backups of the database. 

`DBInstanceClass`: This property specifies the instance class for the RDS database instance. 

You may have noticed we referenced parameters for the `BackupRetentionPeriod` and `DBInstanceClass` properties. We add these parameters as well:

```yaml
Parameters:
  BackupRetentionPeriod:
    Type: Number
    Default: 0
  DBInstanceClass: 
    Type: String
    Default: db.t4g.micro
```

The `BackupRetentionPeriod` default value of 0 is not optimal for production environments, as you may want to retain automated backups of your database for data recovery, compliance and regulation requirements, operational best practices, or testing and developement purposes. We are simply setting it this way to remain in the free tier of AWS. 

We also have set the `InstanceClass` parameter that we reference for the `InstanceClass` property to `db.t4g.micro`, which, according to AWS documentation is "designed for workloads with lower resource requirements and intermittent usage patterns. It can be a cost-effective choice for smaller applications or development/testing environments where consistent high CPU performance is not required."

We continue on, adding and adjusting properties to our RDS `template.yaml` . 

```yaml
  Database:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-rds-dbinstance.html
    Type: AWS::RDS::DBInstance
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html
    DeletionPolicy: 'Snapshot'
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatereplacepolicy.html
    UpdateReplacePolicy: 'Snapshot'
    Properties: 
      AllocatedStorage: '20'
      AllowMajorVersionUpgrade: true
      AutoMinorVersionUpgrade: true
      BackupRetentionPeriod: !Ref BackupRetentionPeriod
      DBInstanceClass: !Ref DBInstanceClass
      DBInstanceIdentifier: !Ref DBInstanceIdentifier
      DBName: !Ref DBName
      DBSubnetGroupName: !Ref DBSubnetGroup

```

We've added a few properties to the `DBInstance`, and we've also given it a reference of `Database`. Here's a bit more on the added properties:

`DBInstanceIdentifier`: This property specifies the identifier for the Amazon RDS database instance. The identifier is a user-defined name that identifies the RDS instance within our AWS account.

`DBName`: This property specifies the name of the initial database that will be created in the Amazon RDS instance. When the RDS instance is provisioned, this database will be created and available for use.

`DBSubnetGroupName`: This property specifies the name of the DB subnet group associated with the RDS instance. A DB subnet group is a collection of subnets in our VPC where RDS instances can be created. The subnet group defines the network configuration for the RDS instance, including the availability zones and subnets where the instance will be placed.

We also add parameters for these properties:

```yaml
  DBInstanceIdentifier: 
    Type: String
    Default: cruddur-instance
  DBName: 
    Type: String
    Default: cruddur
```

As for `DBSubnetGroup`, it's an AWS resource we must define, so we start on it in our RDS `template.yaml`. 

```yaml
DBSubnetGroup:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-rds-dbsubnetgroup.html
    Type: AWS::RDS::DBSubnetGroup
    Properties:

```

We move back to our RDS instance and continue on, defining more properties: 

```yaml
  Database:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-rds-dbinstance.html
    Type: AWS::RDS::DBInstance
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html
    DeletionPolicy: 'Snapshot'
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatereplacepolicy.html
    UpdateReplacePolicy: 'Snapshot'
    Properties: 
      AllocatedStorage: '20'
      AllowMajorVersionUpgrade: true
      AutoMinorVersionUpgrade: true
      BackupRetentionPeriod: !Ref BackupRetentionPeriod
      DBInstanceClass: !Ref DBInstanceClass
      DBInstanceIdentifier: !Ref DBInstanceIdentifier
      DBName: !Ref DBName
      DBSubnetGroupName: !Ref DBSubnetGroup
      DeletionProtection: !Ref DeletionProtection
      EnablePerformanceInsights: true
      Engine: postgres
      EngineVersion: !Ref EngineVersion

# Must be 1 to 63 letters or numbers.
# First character must be a letter.
# Can't be a reserved word for the chosen database engine.
      MasterUsername:  !Ref MasterUsername
      # Constraints: Must contain from 8 to 128 characters.
      MasterUserPassword: !Ref MasterUserPassword
      PubliclyAccessible: true
      VPCSecurityGroups:
        - !GetAtt RDSPostgresSG.GroupId 
```

More on the new properties we added: 

`DeletionProtection`: This property enables deletion protection for the RDS instance. When deletion protection is enabled, it prevents accidental deletion of the RDS instance. 

`EnablePerformanceInsights`: This property enables Performance Insights for the RDS instance. Performance Insights is a feature that helps you monitor the performance of your RDS database. 

`Engine`: This property specifies the database engine to be used for the RDS instance. In our case, it is set to postgres, indicating that PostgreSQL will be used as the database engine.

`EngineVersion`: This property specifies the version of the database engine to be used. 

`MasterUsername`: This property specifies the username for the master user of the RDS instance. The master user has administrative privileges and is used to manage the database.

`MasterUserPassword`: This property specifies the password for the master user of the RDS instance. As we commented in the code, the `MasterUserPassword` must contain from 8 to 128 characters.

`PubliclyAccessible`: This property determines whether the RDS instance can be accessed publicly over the internet. Setting it to `true` allows public access, while setting it to `false` restricts access to within the VPC.

`VPCSecurityGroups`: This property specifies the VPC security groups associated with the RDS instance.

We also add additional parameters for the properties that reference them, but we'll come back to `MasterUsername` and `MasterUserPassword`:

```yaml
 DeletionProtection:
    Type: String
    AllowedValues:
      - true
      - false
    Default: true
  EngineVersion: 
    Type: String
    #  DB Proxy only supports very specific versions of Postgres
    #  https://stackoverflow.com/questions/63084648/which-rds-db-instances-are-supported-for-db-proxy
    Default: '15.2'
```

We move back to the `DBSubnetGroup` we started and continue on adding properties for that resource: 

```yaml
  DBSubnetGroup:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-rds-dbsubnetgroup.html
    Type: AWS::RDS::DBSubnetGroup
    Properties:
      DBSubnetGroupName: !Sub "${AWS::StackName}DBSubnetGroup"
      DBSubnetGroupDescription: !Sub "${AWS::StackName}DBSubnetGroup"
      SubnetIds: { 'Fn::Split' : [ ','  , { "Fn::ImportValue": { "Fn::Sub": "${NetworkingStack}PublicSubnetIds" }}] }
```

`DBSubnetGroupName`: we're defining the name of our DB subnet group. It's going to substitute the property value with the stack name followed by "DBSubnetGroup"

`DBSubnetGroupDescription`: we are defining the description of the DB subnet group here. It's value is the same as `DBSubnetGroupName`

`SubnetIds`: we're defining the list of subnet IDs that will be associated with the DB subnet group. We're importing the value from the network layer for the `PublicSubnetIds` property. Using the `Fn::Split` function, we're splitting the retrieved subnet IDs from `PublicSubnetIds` and creating a list.

To use the `PublicSubnetIds` property for `SubnetIds`, we add the network layer as a parameter, as we did previously in our cluster layer.

```yaml
Parameters:
  NetworkingStack:
    Type: String  
    Description: This is our base layer of networking components e.g. VPC, Subnets
    Default: CrdNet
```

We now move onto our `RDSPostgresSG` security group and continue working on that in our RDS `template.yaml`: 

```yaml
  RDSPostgresSG: 
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html
    Type: AWS::EC2::SecurityGroup
    Properties: 
      GroupName: !Sub "${AWS::StackName}AlbSG"
      GroupDescription: Public Facing SG for our Cruddur ALB
      VpcId: 
        Fn::ImportValue:
          !Sub ${NetworkingStack}VpcId 
      SecurityGroupIngress:
        - IpProtocol: tcp
          SourceSecurityGroupId:
            Fn::ImportValue:
              !Sub ${ClusterStack}ServiceSecurityGroupId       
          FromPort: 5432
          ToPort: 5432
          Description: ALB HTTP 
```
No need to break down these properties, we've already seen a security group. You might notice however that `SourceSecurityGroupId` property is importing the value of `ServiceSecurityGroupId` from the cluster stack. We have not yet created this yet. 

Andrew explains: "When we launch our service, its supposed to have access to this(Postgres security group) so we're supposed to add it here. The problem is we've yet to create our service, but we're setting this up right now. We need to have already in place, the service security group."

This should resolve the issue we were running into with our service layer being deployed to CloudFormation. We go ahead and move back to our cluster `template.yaml` and add the security group:

```yaml
# We have to create this SG before the service so we can pass it to database SG
  ServiceSG:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html
    Type: AWS::EC2::SecurityGroup
    Properties: 
      GroupName: !Sub "${AWS::StackName}ServSG"
      GroupDescription: Security for Fargate Services for Cruddur
      VpcId: 
        Fn::ImportValue:
          !Sub ${NetworkingStack}VpcId 
      SecurityGroupIngress:
        - IpProtocol: tcp
          SourceSecurityGroupId: !GetAtt ALBSG.GroupId
          FromPort: 80
          ToPort: 80
          Description: ALB HTTP
```

We're adding access to our existing `ALBSG` through use of the `SourceSecurityGroupId` property value. Since it's within the same stack, we're using `!GetAtt` to retrieve the attribute `GroupId` from `ALBSG`. We also access the `ServiceSG` from our service `template.yaml` and completely remove it, as it's now being defined in our RDS layer instead. Since we're still going to need to define the security group in our service layer, we need to export `ServiceSG` from our cluster `template.yaml`.

```yaml
  ServiceSecurityGroupId:
    Value: !GetAtt ServiceSG.GroupId
    Export:
      Name: !Sub "${AWS::StackName}ServiceSecurityGroupId"
```

Since we're going to import this value in our RDS layer, we must add the `ClusterStack` to our parameters in the RDS `template.yaml`:

```yaml
  ClusterStack:
    Type: String
    Description: This is our FargateCluster
    Default: CrdCluster
```

We move back over to our RDS `template.yaml` again and come back to the `MasterUsername` and `MasterUserPassword` properties of our `Database`. We use the `!Ref` function to pass values for both properties using parameters. We name the parameters according to the property name, then define the parameters:

```yaml
  MasterUsername:
    Type: String
  MasterUserPassword:
    Type: String
    NoEcho: true
```

We're using the `NoEcho` parameter property for the `MasterUserPassword` after consulting AWS documentation for this. According to AWS, "Whether to mask the parameter value to prevent it from being displayed in the console, command line tools, or API. If you set the `NoEcho` attribute to `true`, CloudFormation returns the parameter value masked as asterisks for any calls that describe the stack or stack events,".

With that, we have defined parameters not explicitly set in the `Parameters` field of the RDS template. For these, we create another `config.toml` file, in our `./aws/cfn/db` directory and implement it: 

```toml
[deploy]
bucket = 'jh-cfn-artifacts'
region = 'us-east-1'
stack_name = 'CrdDb'

[parameters]
NetworkingStack = 'CrdNet'
ClusterStack = 'CrdCluster'
MasterUsername = 'root'
```

We're not passing a parameter for `MasterUserPassword` because that's sensitive information we don't want to show. We will handle this in a moment. For now, we move onto creating our RDS script, so we navigate to our `./bin/cfn` directory and create a new script named `db-deploy`. 

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/db/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/db/config.toml"

cfn-lint $CFN_PATH 

BUCKET=$(cfn-toml key deploy.bucket -t $CONFIG_PATH)
REGION=$(cfn-toml key deploy.region -t $CONFIG_PATH)
STACK_NAME=$(cfn-toml key deploy.stack_name -t $CONFIG_PATH)
PARAMETERS=$(cfn-toml params v2 -t $CONFIG_PATH)

aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --s3-bucket $BUCKET \
    --region $REGION \
    --template-file $CFN_PATH \
    --no-execute-changeset \
    --tags group="cruddur-db" \
    --parameter-overrides $PARAMETERS MasterUserPassword=$DB_PASSWORD \
    --capabilities CAPABILITY_NAMED_IAM
```

The script is very much like our other scripts. We've updated `CFN_PATH` and `CONFIG_PATH` to the pathing for our RDS template and RDS `config.toml` file respectively. You will also notice that we're overriding the parameter for `MasterUserPassword` with the value of the env var `$DB_PASSWORD` by way of the `--parameter-overrides` command. 

From there, we now need to set the `$DB_PASSWORD` env var from our terminal. I'll redact my Postgres database password and instead use "example" for reference point here: 

```sh
export DB_PASSWORD=example
gp env DB_PASSWORD=example
```

Our RDS layer looks to be nearing completion. With that, the `Outputs` parameters we have added to our cluster `template.yaml` will need to be available to us before we can deploy the RDS layer. So we redeploy the cluster layer, running `cluster-deploy`. Then we execute the changeset created from CloudFormation. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/30809d18-bd65-4af5-8d6d-7ef057fa44b0)

The cluster layer updates successfully. We make the RDS script executable by chmod'ing the file: `chmod u+x ./bin/cfn/db-deploy`, then we run the script. Andrew receives an error from `cfn-lint`, as he's implemented the `DBSubnetGroup` resource property `SubnetIds` using multiple lines.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/1347a1d1-9603-413d-8bb4-0615ea0b9a2a)

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/48571a74-2831-4d2b-9060-4334b35cae39)

My changeset is created successfully however, due to implementing the `SubnetIds` in one line:

```yaml
SubnetIds: { 'Fn::Split' : [ ','  , { "Fn::ImportValue": { "Fn::Sub": "${NetworkingStack}PublicSubnetIds" }}] }
```

Andrew adjusts his `SubnetIds` to the same as mine, and informs us that this is the exact example he's been telling us about where sometimes certain functions will not work inside of other ones. In these cases, you have to use the `.json` equivalent of the function instead of the `.yaml` version. (i.e. Fn::Sub instead of !Sub )

We execute the changeset from CloudFormation. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/c89d58ab-f3a3-49d4-9165-3bf6d12fbe74)

Our database has been created successfully. We select the `cruddur-instance` resource from CloudFormation which redirects us to RDS in AWS. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/bf0e3af0-f040-4670-b99f-51c4bd36eb7f)

You can see that we now have our original database, `cruddur-db-instance` and our new database, `cruddur-instance`. There's no data in our new one yet, Andrew mentions we COULD load a snapshot to prefill our data, but instead we're likely going to reseed it at a later time. Andrew also lets us know that the `CONNECTION_URL` to our database is going to be a bit different as well, so we navigate over to AWS System Manager, then Parameter Store to update this parameter. 

![42 56 into CFN RDS Finish ConnectionURLParameter](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/ed158eaf-d361-4312-86e8-d9ef1c568caf)

This should complete our RDS layer. Now that it's implemented and deployed, we can now go back and fix our service layer, as we should have the resources available in the same VPC (security group we added) to fix the health checks passing on our service tasks. 

## Service Layer: First Blood Part II

We begin by going back to our service `template.yaml`, as we need to reference the security group we created in our cluster layer. We're already referencing the `ClusterStack` as a parameter, so we import the value of the `ServiceSecurityGroupId` for the `SecurityGroups` property of the `FargateService` resource. 

```yaml
          SecurityGroups:
            - Fn::ImportValue:
                !Sub "${ClusterStack}ServiceSecurityGroupId"
```

We again run the `service-deploy` script, but a changeset is not created. Instead, we receive an error: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/5abc53d1-af9a-4128-be2a-80b2428816c5)

The error is because we're still exporting the value of `ServiceSecurityGroupId` from our service `template.yaml`, but we've since removed that security group from the service template and implemented it in our cluster layer instead. We fix the error by removing the `Outputs` on our service `template.yaml`. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/3377dfcd-87ae-4547-88cc-fef1adfb50b4)

We again run `./bin/cfn/service-deploy` and this time a changeset is created. We move over to CFN and execute it. After a bit of time, we check our Events tab in CloudFormation on the service stack and see most of the resources with a status of `CREATE_COMPLETE`. The service itself is still in a `CREATE_IN_PROGRESS` status. We move over to ECS to view the backend service. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/029ce7a4-57cf-41b3-9c0e-355d4600e544)

We've already had 2 tasks fail, so the service still isn't working. When we check the logs, they're passing the container health checks:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/e789a60c-3631-4868-b32e-72024c7ce0ae)

We check the security group of the service in EC2, checking the inbound rules. It's using port 80.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/db3e6c72-336c-418c-a133-758fef14adba)

We move over to RDS to check the database security group, redirecting back to EC2 again. Then, we look at the inbound rules for the database:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/04e7b4ce-02e7-4bb0-a526-6c2ab6b21440)

The inbound rules to the database are setup correctly. It's opening port 5432 (Postgres port) to our `CrdClusterServSG`. 

We head back over to our backend service and view one of the failed tasks, and it's still failing the ELB health checks. 

In attempts to troubleshoot the issue, we update the inbound rules for the backend service SG to allow all traffic from everywhere, but this makes no change. When we check the tasks from the backend target group in EC2, the task is still showing unhealthy. 

We edit the inbound rules of the `CrdDbAlbSG` to open port 5432 (Postgres port) to the internet (0.0.0.0/0). Tasks are still showing unhealthy. 

We head back over to the security group of our original database in EC2 and edit the inbound rules to open port 5432 (Postgres port) to the internet (0.0.0.0/0) just like `CrdDbAlbSG`. We also head back over to Systems Manager, then Parameter Store and adjust the `CONNECTION_URL` parameter back to its original value to see if we can at least get it working with the original database. This still did not fix the issue. 

We revert the troubleshooting changes we made to our inbound rules and set the `CONNECTION_URL` parameter back to the new database endpoint settings. Next, we head back over to our workspace and access the cluster `template.yaml`. We update the `ServiceSG` properties `FromPort` and `ToPort` for `SecurityGroupIngress`, as these values were originally set to 80 :

```yaml
      SecurityGroupIngress:
        - IpProtocol: tcp
          SourceSecurityGroupId: !GetAtt ALBSG.GroupId
          FromPort: !Ref BackendPort
          ToPort: !Ref BackendPort
```

We're referencing the `BackendPort` parameter, which is set to 4567, as seen in the cluster layer's `Parameters`:

```yaml
  BackendPort:
    Type: Number
    Default: 4567  
```

We also make sure the `Port` property for the `BackendTG` is set to port 4567 as well:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/3cf076a4-95c9-4f96-914f-0e902e7e9e7e)

It's also referencing `BackendPort`, so we're good here. With these changes implemented, we must redploy the cluster layer again. First, we tear down the existing service stack from CFN, then run our `cluster-deploy` script and execute the changeset. When this updates successfully, we run our `service-deploy` script again as well. We execute this changeset from CloudFormation, and let the resources be created. After a bit of time, we head over to ECS and check the status of any tasks running from our backend service:

![11 30 into CFN Service Fixed healthchecksarepassing](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/d79eb92c-f54d-4ccc-94c2-b6eed5f19c3d)

Our health checks are now showing as healthy! With this change, our old database is no longer needed. We head over to RDS and delete the existing `cruddur-db-instance` database:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/6e169b9c-5ea0-4733-912c-f13b8725d57c)

Back in CloudFormation, the service stack is now created as well:

![13 13 into CFN Service Fixed servicelayercompletecreation](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/9633604d-839f-4599-a600-93cfd5c5669d)

We test our endpoint by navigating to api.thejoshdev.com/api/health-check but the page does not resolve. This is because our new load balancer is not being pointed to in Route53 in AWS. We navigate over to Route53 in AWS and update the A records for `api.thejoshdev.com` and select our new ALB. 

![14 28 into CFN Service Fixed changedapiroutingroute53](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/8f6eccec-246d-49ef-b988-bf60c65d5e15)

Now, we can test our backend service from a web browser by manually going to the endpoint.

![14 28 into CFN Service Fixed endpointresolves](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/4588a4b7-269c-4560-80fd-55b1cac2cfbf)

With that, our backend service layer should be complete. We're now able to move onto our DyanmoDB, as we're going to use SAM CFN templates to implement this through CloudFormation. 

## DynamoDB Layer (SAM)

A little bit on SAM. SAM, or Serverless Application Model CloudFormation templates are an extension of CloudFormation templates. They're specifically designed for building serverless applications. I asked ChatGPT to give us some key features of using SAM CFN templates:

"Here are some key features and benefits of SAM CFN templates:

1. Simplified Syntax: SAM templates provide a simplified syntax that reduces the amount of code needed to define serverless resources compared to traditional CloudFormation templates. This makes it easier to author and read templates for serverless applications.

2. Serverless Resources: SAM introduces new resource types and properties that are optimized for serverless applications, such as AWS Lambda functions, Amazon API Gateway APIs, Amazon DynamoDB tables, and AWS Step Functions state machines. These resources can be defined in a more concise and expressive manner in SAM templates.

3. Built-in Transform: SAM templates use a built-in CloudFormation transform called AWS::Serverless-2016-10-31. This transform automatically converts SAM-specific resources and properties into their equivalent CloudFormation resources during deployment. It allows you to use SAM features without sacrificing the flexibility and power of CloudFormation.

4. Local Development and Testing: SAM provides a local development and testing experience through the AWS SAM CLI (Command Line Interface). With the SAM CLI, you can invoke and debug Lambda functions locally, emulate AWS service integrations, and package and deploy your application to AWS. SAM templates work seamlessly with the SAM CLI, enabling efficient local development and testing workflows.

5. Predefined Event Sources: SAM templates offer predefined event sources that simplify the configuration of event-driven architectures. For example, you can define an Amazon S3 bucket as an event source for a Lambda function directly in the template, without the need for additional configuration.

6. Resource Policies: SAM templates support resource policies that allow you to define fine-grained access control for your serverless resources. Resource policies enable you to set permissions at the resource level, defining who can invoke your Lambda functions or access your API Gateway APIs.

Overall, SAM CFN templates provide a higher-level abstraction and convenience for building serverless applications on AWS. They make it easier to define and deploy serverless resources and integrate them with other AWS services."

We start off the DynamoDb layer by creating a new folder named `ddb` within our `./aws/cfn` directory. Then we create our `template.yaml` and `config.toml` files in the folder. We then head over to `./bin/cfn` and create `ddb-deploy` as our script to deploy the DDB layer. We start off with the `ddb-deploy` script, copying the contents of the `db-deploy` script and editing it as we go: 

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/ddb/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/ddb/config.toml"

cfn-lint $CFN_PATH 

BUCKET=$(cfn-toml key deploy.bucket -t $CONFIG_PATH)
REGION=$(cfn-toml key deploy.region -t $CONFIG_PATH)
STACK_NAME=$(cfn-toml key deploy.stack_name -t $CONFIG_PATH)
PARAMETERS=$(cfn-toml params v2 -t $CONFIG_PATH)

aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --s3-bucket $BUCKET \
    --region $REGION \
    --template-file $CFN_PATH \
    --no-execute-changeset \
    --tags group="cruddur-ddb" \
    --parameter-overrides $PARAMETERS \
    --capabilities CAPABILITY_NAMED_IAM
```

As always, we update `CFN_PATH` and `CONFIG_PATH` to reflect our DDB pathings. We now move back to our ddb `template.yaml` and begin implementing it. We access our existing `./bin/ddb/schema-load` script to cross reference when creating our DDB `template.yaml`. First we start with our DynamoDB table, which we're calling `DynamoDBTable`:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: |
  - DynaomDB Table
  - DynamoDB Stream
Parameters: 
Resources:
  DynamoDBTable:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-dynamodb-table.html
    Type: AWS::DynamoDB::Table
    Properties: 
      AttributeDefinitions: 
        - AttributeName: message_group_uuid
          AttributeType: S
        - AttributeName: pk
          AttributeType: S
        - AttributeName: sk
          AttributeType: S
      TableClass: STANDARD
      KeySchema: 
        - AttributeName: pk
          KeyType: HASH
        - AttributeName: sk
          KeyType: RANGE
      ProvisionedThroughput: 
        ReadCapacityUnits: 5
        WriteCapacityUnits: 5
      BillingMode: PROVISIONED
      DeletionProtectionEnabled: true
      GlobalSecondaryIndexes: 
        - IndexName: message-group-sk-index
          KeySchema: 
            - AttributeName: message_group_uuid
              KeyType: HASH
            - AttributeName: sk
              KeyType: RANGE
          Projection: 
            ProjectionType: ALL
          ProvisionedThroughput: 
            ReadCapacityUnits: 5
            WriteCapacityUnits: 5
      StreamSpecification:
        StreamViewType: NEW_IMAGE
```

Immediately, what's different about this template from our others is the `Transform: AWS::Serverless-2016-10-31` line. This line indicates that the template uses the AWS Serverless transform. It enables the use of SAM-specific resources and properties. 

Here's some information on the properties of `DynamoDBTable`: 

`AttributeDefinitions`: This property defines the attribute definitions for the table. Each attribute definition consists of an `AttributeName` and its corresponding `AttributeType`. The `AttributeName` represents the name of the attribute, and the `AttributeType` represents the data type of the attribute (e.g., 'S' for string, 'N' for number, 'B' for binary).

`TableClass`: Specifies the class of the table. You can choose between `STANDARD`, which uses provisioned throughput, and `PAY_PER_REQUEST`, which uses on-demand capacity mode.

`KeySchema`: Defines the primary key schema for the table. The primary key consists of one or two attributes: the partition key (HASH) and an optional sort key (RANGE). The `KeySchema` property specifies the attribute names and their key types (either HASH or RANGE).

`ProvisionedThroughput`: Specifies the provisioned read and write capacity units for the table. You can set the `ReadCapacityUnits` and `WriteCapacityUnits` properties to determine the desired capacity.

`BillingMode`: Indicates the billing mode for the table. You can choose between `PROVISIONED`, which uses capacity mode, or `PAY_PER_REQUEST`, which uses on-demand mode, similar to `TableClass`.

`DeletionProtectionEnabled`: Pretty self explanatory. Enables or disables deletion protection for the table. When deletion protection is enabled, the table cannot be deleted through normal CloudFormation stack updates or deletions.

`GlobalSecondaryIndexes`: This property allows you to define one or more global secondary indexes (aka GSIs) for the table. Each GSI has its own `IndexName`, `KeySchema`, `Projection`, and `ProvisionedThroughput` properties, similar to the primary key schema.

`LocalSecondaryIndexes`: Similar to `GlobalSecondaryIndexes`, this property enables you to define one or more local secondary indexes (aka LSIs) for the table. LSIs use the same partition key as the table but have a different sort key.

`StreamSpecification`: Configures the stream specification for the table. You can set the `StreamViewType` property to specify what information is included in the stream. Valid values for `StreamViewType` are `NEW_IMAGE`, `OLD_IMAGE`, `NEW_AND_OLD_IMAGES`, or `KEYS_ONLY`.

Moving on, we also define our serverless function, which we call `ProcessDynamoDBStream`. This is for our Lambda function. We use our existing one called `cruddur-messaging-stream` from AWS Lambda to cross reference: 

```yaml
  ProcessDynamoDBStream:
    # https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-resource-function.html
    Type: AWS::Serverless::Function
    Properties:
      Handler: lambda_handler
      Runtime: python3.8
      Events:
        Stream:
          Type: DynamoDB
          Properties:
            Stream: !GetAtt DynamoDBTable.StreamArn
            BatchSize: 100
            StartingPosition: TRIM_HORIZON
```

We'll break this down in a bit, but at this point, we decide that we want to define an execution role for the Lambda. We start with the policy, which we're going to add inline to our role. We head over to IAM in AWS and reference our `cruddur-messageing-stream-role` that we created as the execution role for our existing `cruddur-messageing-stream` Lambda function. We allow ChatGPT to assist us, generating the policies from our existing ones attached to the `cruddur-messageing-stream-role` in AWS. Then we add it to the role: 

```yaml
  LambdaLogGroup:
    Type: "AWS::Logs::LogGroup"
    Properties: 
      LogGroupName: "/aws/lambda/cruddur-messaging-stream"
      RetentionInDays: 14
  LambdaLogStream: 
    Type: "AWS::Logs::LogStream"
    Properties:
      LogGroupName: !Ref LambdaLogGroup
      LogStreamName: "LambdaExecution"
  ExecutionRole:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-role.html
    Type: AWS::IAM::Role
    Properties: 
      RoleName: 'CruddurDdbStreamExecRole'
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: 'Allow'
            Principal:
              Service: 'lambda.amazonaws.com'
            Action: 'sts:AssumeRole'
      Policies:            
        - PolicyName: "LambdaExecutionPolicy"
          PolicyDocument: 
            Version: "201-10-17"
            Statement: 
              - Effect: "Allow"
                Action: "logs:CreateLogGroup"
                Resource: !Sub "arn:aws:logs:${AWS::Region}:${AWS::AccountId}:*"
              - Effect: "Allow"
                Action:
                  - "logs:CreateLogStream"
                  - "logs:PutLogEvents"
                Resource: !Sub "arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:${LambdaLogGroup}:*"
              - Effect: "Allow"
                Action: 
                  - "ec2:CreateNetworkInterface"
                  - "ec2:DeleteNetworkInterface"
                  - "ec2:DescribeNetworkInterfaces"
                Resource: "*"
              - Effect: "Allow"
                Action:
                  - "lambda:InvokeFunction"
                Resource: "*"
              - Effect: "Allow"
                Action:
                  - "dynamodb:DescribeStream"
                  - "dynamodb:GetRecords"
                  - "dynamodb:GetShardIterator"
                  - "dynamodb:ListStreams"
                Resource: "*"
```

`LambdaLogGroup`: This resource is of type `AWS::Logs::LogGroup`. It represents a CloudWatch Logs log group. It defines properties such as the `LogGroupName`, which is set to `/aws/lambda/cruddur-messaging-stream`, and `RetentionInDays`, which specifies that logs should be retained for 14 days.

`LambdaLogStream`: This represents a CloudWatch Logs log stream. It is associated with the `LambdaLogGroup` defined above. 

`ExecutionRole`: This is our IAM role we're defining. You may notice the `Service` property is different from how we defined an `sts:AssumeRole` action in our service `template.yaml`. Instead of `ecs-tasks.amazonaws.com`, we're using `lambda.amazonaws.com`. 

The policy portion defines the necessary permissions for the `ExecutionRole` to perform actions such as creating and managing CloudWatch Logs, working with network interfaces, invoking Lambda functions, and interacting with DynamoDB streams.

We now have to attach the role to our Lambda (serverless function). We also continue on adding more properties for the Lambda, cross referencing the existing one: 

```yaml
  ProcessDynamoDBStream:
    # https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-resource-function.html
    Type: AWS::Serverless::Function
    Properties:
      Architectures: arm64
      CodeUri: ???
      Handler: lambda_handler
      Runtime: !Ref PythonRuntime
      Role: !GetAtt ExecutionRole.Arn
      Events:
        Stream:
          Type: DynamoDB
          Properties:
            Stream: !GetAtt DynamoDBTable.StreamArn
            BatchSize: 100
            StartingPosition: TRIM_HORIZON
```

While referencing our existing `cruddur-messaging-stream` Lambda, we noticed the Runtime was set to Python3.9 instead of 3.8. Since this is changing, we decided to add a parameter for that property instead and reference it. 

```yaml
Parameters: 
  PythonRuntime: 
    Type: String
    Default: python3.9
```

We've added `Architectures` as a property. This will indicate that the function should be built for the `arm64` architecture. We've also added `CodeUri`, which is the location of the function's code. Since we're not sure yet, we've set a placeholder of "???" for now. 

`Handler: lambda_handler`: Specifies the name of the function's handler.

`Events`: Defines the events that trigger the function. In this case, it includes a single event named `Stream` of type `DynamoDB`, which triggers the function in response to DynamoDB stream records.

`Type: DynamoDB`: Indicates that the event source is a DynamoDB stream.

`Stream: !GetAtt DynamoDBTable.StreamArn`: Specifies the DynamoDB stream ARN that triggers the function. The !GetAtt function is retrieving the ARN of `DynamoDBTable` resource's stream using `DynamoDBTable.StreamArn`.

`BatchSize: 100`: Specifies the number of records to be processed in each batch. In this case, the function will process 100 records at a time.

`StartingPosition: TRIM_HORIZON`: Sets the starting position in the stream when the function is first deployed. `TRIM_HORIZON` indicates that the function should start processing from the oldest available records in the stream. This will process all available records.

We keep on, adding more properties to our lambda function, and editing some as we go: 

```yaml
  ProcessDynamoDBStream:
    # https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-resource-function.html
    Type: AWS::Serverless::Function
    Properties:
      Architectures: arm64
      CodeUri: ???
      InlineCode: ???
      PackageType: ZIP
      Handler: lambda_handler
      Runtime: !Ref PythonRuntime
      Role: !GetAtt ExecutionRole.Arn
      MemorySize: !Ref MemorySize
      Timeout: !Ref Timeout
      Events:
        Stream:
          Type: DynamoDB
          Properties:
            Stream: !GetAtt DynamoDBTable.StreamArn
            # TODO - Does our Lambda handle more than one record?
            BatchSize: 1
            # https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-property-function-dynamodb.html#sam-function-dynamodb-startingposition
            # TODO - Is this the right value? 
            StartingPosition: LATEST
```

More info on the added properties: 

We're still not sure if we need to use `CodeUri` or `InlineCode`. We know because we need the `PackageType` property set to `ZIP`, one of these options will be used. With `InlineCode`, the property would allow us to provide the function's code directly as an inline string.

`PackageType: ZIP`: The `PackageType` property specifies the type of packaging for the function's code. In this case, it is set to `ZIP`, indicating that the code will be packaged as a ZIP file. This is the most common packaging type for Lambda functions.

 `MemorySize: !Ref MemorySize`: Defines the amount of memory allocated to the function during execution.
 
 `Timeout: !Ref Timeout`: The `Timeout` property specifies the maximum execution time for the function in seconds.
 
 We've updated the `BatchSize` property to 1 instead of 100, as it was set before. This property sets the number of records to be processed in each batch.
 
 We've also updated `StartingPosition` from `TRIM_HORIZON` to `LATEST`. This property determines the starting position in the DynamoDB stream when the function is first deployed. Setting it to `LATEST` instructs the function to start processing from the most recent record in the stream. This ensures that the function consumes only the new records that arrive after deployment. As you can see from our comments, we're questioning if this is correct at this time. 
 
 We also add parameters for the `MemorySize` and `Timeout` properties.
 
 ```yaml
   MemorySize:
    Type: Number
    Default: 128
  Timeout: 
    Type: Number
    Default: 3
 ```
 
 Our Lambda is starting to look better, so we direct our attention towards implementing SAM into our DDB layer. We need to install it into our workspace, so we open our `.gitpod.yml` file and add it: 
 
 ```yaml
 tasks:
  - name: aws-sam
    init: |
      cd /workspace
      wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
      unzip aws-sam-cli-linux-x86_64.zip -d sam-installation
      sudo ./sam-installation/install
      cd $THEIA_WORKSPACE_ROOT
 ```
 
 So we don't have to restart our workspace, we run these commands line by line in our terminal to install SAM into our current environment. With that completed, we now are deciding how we want to implement SAM. We check through the CLI to see what is available from SAM by just typing `SAM`:
 
 ![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/b3d8b794-9b9a-4f7a-a0e6-70ba8c462e38)

We know we want to use the `build` command, so we head back over to our `ddb-deploy` script and clear it, as the CFN commands we've set here aren't going to work for SAM. We also know we're going to need the `sam package` and `sam deploy` commands so we add them both: 

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-build.html
sam build 

# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-package.html
sam package 

# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-deploy.html
sam deploy 
```

From here, we work through the script, adding options for the commands, staring with `sam build`: 

```sh
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-build.html
sam build \
--template \
--parameter-overrides
--build-dir
--base-dir
--region $AWS_DEFAULT_REGION   
```

These are defaults that we copied over from documentation thus far. We manually run the command for `sam build` from the terminal, and receive an error to see what it's asking for: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/5ab54c71-354d-4d05-b6c7-80f9ae267012)

Our existing function sits in `./aws/lambdas` as `cruddur-messaging-stream.py`. We create a new folder in the `./aws/lambdas` directory named `cruddur-messaging-stream`, then move the existing function file to the folder. We then rename the file to `lambda-function.py` to match what it's named in AWS. We get the path to the file, and add it as a variable named `FUNC_PATH` to our `ddb-deploy` script.

```sh
FUNC_DIR="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas/cruddur-messaging-stream/"
```

We then use the variable in our command for `sam build`:

```sh
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-build.html
sam build \
--template \
--parameter-overrides
--build-dir $FUNC_DIR
--base-dir $FUNC_DIR
--region $AWS_DEFAULT_REGION 
```

We comment out our other commands from the script, then attempt to run it: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/30866116-7a19-4e18-a194-a61640361447)

With that error, we need to add another variable for our template path, so we do. Then we implement the variable as well. We also comment out our `--parameter-overrides` option for now and add another variable for our SAM configuration path, adding an option for it too. 

```sh
FUNC_DIR="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas/cruddur-messaging-stream/"
TEMPLATE_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/ddb/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/ddb/config.toml"

# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-build.html
sam build \
--config $CONFIG_PATH \
--template $TEMPLATE_PATH \
--build-dir $FUNC_DIR \
--base-dir $FUNC_DIR \
--region $AWS_DEFAULT_REGION 
#--parameter-overrides
```

We run the script again, not expecting it to work, just seeing what else we need to add. Here's the error output:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/0de9c7dd-8526-444e-8ecb-3636d3c1654a)

We correct the error by editing our option for the configuration file.

```sh
FUNC_DIR="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas/cruddur-messaging-stream"
TEMPLATE_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/ddb/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/ddb/config.toml"

# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-build.html
sam build \
--config-file $CONFIG_PATH \
--template $TEMPLATE_PATH \
--build-dir $FUNC_DIR \
--base-dir $FUNC_DIR \
--region $AWS_DEFAULT_REGION 
#--parameter-overrides
```

We again run the script:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/8fe800c7-69d5-470a-9ca7-40bc5ee75cc5)

This is because our existing `config.toml` in the `./aws/cfn/ddb` directory is empty. We consult AWS documentation for reference. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/00b9e540-0680-4a1a-a935-fb4aecee6b24)

In a SAM configuration file, you can set different parameters for different SAM commands. With a good point of reference, we begin implementing our `config.toml` using the SAM configuration structure, setting parameters for each of our SAM commands:

```toml
version=0.1
[default.build.parameters]
region = "us-east-1"

[default.package.parameters]
region = "us-east-1"

[default.deploy.parameters]
region = "us-east-1"
```

Since we're setting the `region` parameter here, we remove it from our `ddb-deploy` script. 

```sh
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-build.html
sam build \
--config-file $CONFIG_PATH \
--template-file $TEMPLATE_PATH \
--base-dir $FUNC_DIR 
# --parameter-overrides 
```

We run `ddb-deploy` again: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/0bb0be53-c578-4d24-b9d5-fc54aa966e9b)

We're told from the terminal that the build succeeded, so we go in search of the artifacts and template files it built. Our `build.toml` file that was auto-generated was placed into our `./aws/lambdas` directory. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/da67749b-eb35-46ce-8a21-82ef04411271)

This wasn't the intended result, so we check Source Control from our workspace and discard the changes, deleting the file. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/0a6f19a7-4ef5-43b2-9274-29dc98bdf26a)

We adjust the `FUNC_DIR` pathing in our `ddb-deploy` script, adding a `/` to the end of the path.

```sh
FUNC_DIR="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas/cruddur-messaging-stream/"
```

Then run the `ddb-deploy` script again. The build succeeds again. This makes no difference. The `build.toml` file is placed into the same location as before. This leads us to adjusting our `.gitignore` file, so this file does not persist within our environment. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/1a1015d2-2dc7-45f5-938f-03b0175800a3)

We move on, now working on the `sam package` command in the `ddb-deploy` script: 

```sh
FUNC_DIR="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas/cruddur-messaging-stream/"
TEMPLATE_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/ddb/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/ddb/config.toml"
ARTIFACT_BUCKET="jh-cfn-artifacts"

# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-build.html
sam build \
--config-file $CONFIG_PATH \
--template-file $TEMPLATE_PATH \
--build-dir $FUNC_DIR \ 
--base-dir $FUNC_DIR 
# --parameter-overrides 

# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-package.html
sam package \
  --s3-bucket $ARTIFACT_BUCKET \
  --config-file $CONFIG_PATH \
  --template-file $TEMPLATE_PATH \
```

We run our `ddb-deploy` script again, and the build completes. Here's the output from the `sam package` command portion: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/70a434ea-6acb-432c-aeb0-e4505fcd34a4)

The output is spit out in the terminal (which is a CFN template) because we haven't told it to dump this information somewhere yet. We move over to S3 in AWS, checking our `jh-cfn-artifacts` bucket to see if the template was uploaded. It was not. We need to specify where the template file is written so it doesn't default to the standard output. 

We comment out the option from our `sam build` command in the script for `--base-dir` and run the script again: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/908a240b-1989-463f-826c-503effcece7a)

This updates our directory where the artifacts are built to, so we remove the `--base-dir` option altogether. We can see the the `build` directory and the `template.yaml` file generated are now going to the correct location: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/e066eeab-03fe-4d06-8498-e32cafe45955)

We can now continue working on the `sam package` command in our `ddb-deploy` script. We add variables for the `sam package` command, specifying a new value for `TEMPLATE_PATH` to match the location generated by the `sam build` command, and `OUTPUT_TEMPLATE_PATH` to specify the path for the outputted `packaged.yaml` file. Next, we add an option for the `--output-template-file` and use the new variable. We also add an option to give an S3 prefix:

```sh
TEMPLATE_PATH="/workspace/aws-bootcamp-cruddur-2023/.aws-sam/build/template.yaml"
OUTPUT_TEMPLATE_PATH="/workspace/aws-bootcamp-cruddur-2023/.aws-sam/build/packaged.yaml"

# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-package.html
sam package \
  --s3-bucket $ARTIFACT_BUCKET \
  --config-file $CONFIG_PATH \
  --output-template-file $OUTPUT_TEMPLATE_PATH \
  --template-file $TEMPLATE_PATH \
  --s3-prefix "ddb"
```

We test the `ddb-deploy` script again: 

![1 20 03 into SAM CFN for Dynamodb DynamoDB Streams Lambda buildsucceededSAMtemplate](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/4daeffcb-f7f7-4cb1-9595-7db5d0c22230)

We now have a `packaged.yaml` file in the temporary `.aws-sam/build` directory: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/cd38cecc-2810-4b16-bf5f-86de9ef47a33)

We're now able to begin working on the `sam deploy` portion of the script. We want to make use of the pathing for the new `packaged.yaml` file, as this is what will be deployed. We add another variable for this path named `PACKAGED_TEMPLATE_PATH`. We then implement the rest of the options for the `sam deploy` command: 

```sh
PACKAGED_TEMPLATE_PATH="/workspace/aws-bootcamp-cruddur-2023/.aws-sam/build/packaged.yaml"

# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-deploy.html
sam deploy \
  --template-file $PACKAGED_TEMPLATE_PATH \
  --config-file $CONFIG_PATH \  
  --stack-name "CrdDdb"\
  --tags group="cruddur-ddb" \
  --capabilities "CAPABILITY_IAM"
```

We test the `ddb-deploy` script again. The `build` and `package` steps complete, and deployment is initiated. From the terminal, we can see a changeset is waiting to be created.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/99b445aa-cf2e-4aad-a5b0-29e51311f45d)

The changeset fails to create. We decide to try running the `sam validate`command to validate our template. 

![1 24 30 into SAM CFN for Dynamodb DynamoDB Streams Lambda validateSAM](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/08cf5852-286b-47c5-bd00-3a0463137bfd)

This command is so useful, we decide to add it to our `ddb-deploy` script to run before any of our other commands in the script.

```sh
sam validate -t $TEMPLATE_PATH
```

With the error, we head back over to our `./aws/cfn/ddb/template.yaml` and find that we're still missing values for some properties in our function. Other properties need adjusted as well. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/b35d31ec-8f54-4a4b-8f85-d0afa26786a4)

We make adjustments, specifically removing the `InlineCode` property. We update the case-sensitive value for `ZIP` to `Zip`, and also provide a path for `CodeUri`.

```yaml
    # https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-resource-function.html
    Type: AWS::Serverless::Function
    Properties:
      Architectures: arm64
      CodeUri: .
      PackageType: Zip
      Handler: lambda_handler
      Runtime: !Ref PythonRuntime
      Role: !GetAtt ExecutionRole.Arn
```

We test `ddb-deploy` again: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/dfc6db6f-29d2-4355-83d0-51b2dcfe095c)

We adjust our `Architectures` property to use a list instead:

```yaml
    # https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-resource-function.html
    Type: AWS::Serverless::Function
    Properties:
      Architectures: 
        - arm64
      CodeUri: .
      PackageType: Zip
      Handler: lambda_handler
      Runtime: !Ref PythonRuntime
      Role: !GetAtt ExecutionRole.Arn
```

Then we run `ddb-deploy` again: 

![1 29 55 into SAM CFN for Dynamodb DynamoDB Streams Lambda BuildFailedSAM](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/8dac38bb-f97a-422f-8ad3-05e81057ffc2)

Andrew let's us know that this error indicates we may want to run this in a container. That way we can install dependencies required for our Lambda function. For this, we add the `--use-container` option to our `ddb-deploy` script for the `sam build` command.

```sh
sam validate -t $TEMPLATE_PATH

# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-build.html
# --use-container
# use container is for building the lambda in a container
# its still using the runtimes and its not a custom runtime
sam build \
--use-container \
--config-file $CONFIG_PATH \
--template-file $TEMPLATE_PATH \
--base-dir $FUNC_DIR 
```

We again run our `ddb-deploy` script. The script hangs while mounting the container. 

![1 39 52 into SAM CFN for Dynamodb DynamoDB Streams Lambda usecontainerhangsonmounting](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/60167f6b-3bdd-4ced-a549-7b4761535ca5)

We update `template.yaml` to remove `Architectures` property so it defaults to `x86` instead of `arm64` like we were specifying, as Andrew was able to find other users with the same issue online and this resolved the problem. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/6489d3f7-ac50-4538-bc2b-cdeab68da25b)

We also go to update the `CodeUri` property as well, as others were having issues with the pathing specified there. When we navigate to the `./aws/lambdas/cruddur-messaging-stream` directory (pathing for our Lambda function), we only have a `template.yaml` file in there. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/e4315d92-7061-4af9-a864-22f62efae040)

We have to go back into our previous commits to copy the file back into our workspace, placing the `lambda-function.py` file back into the `./aws/lambdas/cruddur-messaging-stream` directory. Then we delete the `template.yaml` file in the same directory.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/fd86e0c8-4d55-435c-a62b-d3504704781a)

We finish updating the pathing for `CodeUri`: 

```yaml
    # https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-resource-function.html
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: aws/lambdas/cruddur-messaging-stream
      PackageType: Zip
      Handler: lambda_handler
      Runtime: !Ref PythonRuntime
      Role: !GetAtt ExecutionRole.Arn
```

We again run the `ddb-deploy` script, and we pass the build step, then the package step. Before checking if the deploy finished or not, we navigate to the `.aws-sam/build/template.yaml` to see what was generated out:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/21ca06c2-fcee-4bc4-9b23-dba8d2bdb219)

This is not what we specified for `CodeUri` but that's what it replaced it with. When we check the `packaged.yaml` file generated, the `CodeUri` value shows a path for our S3 bucket, `jh-cfn-artifacts`, using the `ddb` prefix we set in the script. Here's a screenshot from Andrew's `packaged.yaml` for reference: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/28f65e8a-0b43-4883-9074-6c1f9566bddc)

That being said, it looks like our deployment did not succeeed, as there's an error when creating the changeset:

![1 47 12 into SAM CFN for Dynamodb DynamoDB Streams Lambda failedtocreatechangeset](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/beaa6f12-49e3-46d2-80c2-6f8a1f49eb13)

We fix the error by updating the `--capabilities` option of our `sam deploy` command to the correct value in `ddb-deploy`:

```sh
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-deploy.html
sam deploy \
  --template-file $PACKAGED_TEMPLATE_PATH \  
  --config-file $CONFIG_PATH \
  --stack-name "CrdDdb"\
  --tags group="cruddur-ddb" \
  --capabilities "CAPABILITY_NAMED_IAM"
```

Instead of running the `ddb-deploy` script again, we decide to break each command up into its own script. We create a new folder in the `./bin` directory named `sam`. Then within `sam`, we create another new folder named `ddb`. We then create 3 new scripts within the `./bin/sam/ddb` directory for each command: `build`, `deploy`, and `package`. Then, we go ahead and break up the `ddb-deploy` script, putting each command into it's corresponding script: 

`./bin/sam/ddb/build`

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

FUNC_DIR="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas/cruddur-messaging-stream/"
TEMPLATE_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/ddb/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/ddb/config.toml"

sam validate -t $TEMPLATE_PATH

echo "== build"
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-build.html
# --use-container
# use container is for building the lambda in a container
# its still using the runtimes and its not a custom runtime
sam build \
--use-container \
--config-file $CONFIG_PATH \
--template-file $TEMPLATE_PATH \
--base-dir $FUNC_DIR 
# --parameter-overrides 
```

`./bin/sam/ddb/deploy`

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

PACKAGED_TEMPLATE_PATH="/workspace/aws-bootcamp-cruddur-2023/.aws-sam/build/packaged.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/ddb/config.toml"

echo "== deploy"
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-deploy.html
sam deploy \
  --template-file $PACKAGED_TEMPLATE_PATH \
  --config-file $CONFIG_PATH \
  --stack-name "CrdDdb"\
  --tags group="cruddur-ddb" \
  --capabilities "CAPABILITY_NAMED_IAM"
```

`./bin/sam/ddb/package`

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

TEMPLATE_PATH="/workspace/aws-bootcamp-cruddur-2023/.aws-sam/build/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/ddb/config.toml"
OUTPUT_TEMPLATE_PATH="/workspace/aws-bootcamp-cruddur-2023/.aws-sam/build/packaged.yaml"
ARTIFACT_BUCKET="jh-cfn-artifacts"

echo "== package"
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-package.html
sam package \
  --s3-bucket $ARTIFACT_BUCKET \
  --config-file $CONFIG_PATH \
  --output-template-file $OUTPUT_TEMPLATE_PATH \
  --template-file $TEMPLATE_PATH \
  --s3-prefix "ddb"
```

We make each script executable, then run each one individually, making sure they work. All is well until the `deploy` script. Our changeset is created successfully, but it executes the changeset on its own and fails. 

![1 48 59 into SAM CFN for Dynamodb DynamoDB Streams Lambda rollbackfailed](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/e40430de-34ad-4857-bd7a-2f4043589c61)

We fix this by adding the option `  --no-execute-changeset` to our `deploy` script: 

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

PACKAGED_TEMPLATE_PATH="/workspace/aws-bootcamp-cruddur-2023/.aws-sam/build/packaged.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/ddb/config.toml"

echo "== deploy"
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-deploy.html
sam deploy \
  --template-file $PACKAGED_TEMPLATE_PATH \
  --config-file $CONFIG_PATH \
  --stack-name "CrdDdb"\
  --tags group="cruddur-ddb" \
  --no-execute-changeset \  
  --capabilities "CAPABILITY_NAMED_IAM"
```

We then remove the `ddb-deploy` script, as we no longer need it. The error also indicated that the `LambdaLogGroup` using property `LogGroupName: "/aws/lambda/cruddur-messaging-stream"` already exists, so we update the `LogGroupName` to `"/aws/lambda/cruddur-messaging-stream00"` in our DDB template. Then we head back over to CloudFormation in AWS and try deleting the DDB stack, but it fails to delete. The DDB table we were creating had Deletion protection enabled, so it won't delete. From our DDB template, we add a parameter for  `DeletionProtectionEnabled` setting the value to false:

```yaml
  DeletionProtectionEnabled:
    Type: String
    Default: false
```

Then we reference the parameter for the property in the DDB table: 

```yaml
      DeletionProtectionEnabled: !Ref DeletionProtectionEnabled
```

From there, we head over to DynamoDB in AWS, and turn off deletion protection for the table:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/dc58d28b-a52d-4134-867c-87f8e172d548)

Then we navigate back to CFN and delete the DDB stack:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/6eb72822-7d16-431d-9cd3-a8243b144549)

Back over in our workspace, we again run all 3 scripts: `build`, `package`, `deploy`: 

![1 54 52 into SAM CFN for Dynamodb DynamoDB Streams Lambda changesetcreated](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/62faf400-c481-46e9-8012-b5884cc23da1)

Our changeset is created successfully, and this time it didn't execute automatically. We head back over to CloudFormation and execute the changeset, which returns an error: 

![end of SAM CFN for Dynamodb DynamoDB Streams Lambda uploadedfilemustbenonempty](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/d6d1145b-70d8-42b0-9ddd-c672402a41b6)

The error indicates the `.zip` file uploaded to CloudFormation is empty. We check this by heading over to S3, and access the `jh-cfn-artifacts` bucket, navigating to the `ddb` folder inside. There's a file (or folder) here, so we download it, then add a `.zip` file extension to it. The folder is most definitely empty:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/8ab49fd0-2caa-43ea-9043-7140fdb08ef1)

We go ahead and empty the `jh-cfn-artifacts` bucket as it was getting quite full. For a better way of keeping this bucket organized, we decide to add the `--s3-prefix` option/flag to each of our scripts.

```sh
    --s3-prefix cluster \
```

```sh
    --s3-prefix db \
```

```sh
    --s3-prefix networking \
```

```sh
    --s3-prefix backend-service \
```

We also initially thought that the Lambda function in our DDB `template.yaml` would run relative to where the `template.yaml` file was located. To test this, we move the `cruddur-messaging-stream` folder containing our `lamba_function.py` file out of the `./aws/lambdas` directory, and into the `./aws/cfn/ddb` directory. Then, we update the `CodeUri` value in the DDB template file to reflect the change: 

```yaml
      CodeUri: cruddur-messaging-stream
```

We run our `build` script to test, just to see where our SAM generated template is building out. The value for `CodeUri` in our generated `template.yaml` appears to be what's being built, and it's being built in the `.aws-sam/build` directory.

We delete the folder that's being built out to test for sure. Then we run the `build` script again. The `ProcessDynamoDBStream` folder IS being created. We expand the folder: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/42284c78-c69c-458f-abbe-f0523aa52800)

Its empty. This is our problem. Further into troubleshooting, we move the `cruddur-messaging-stream` folder containing our function that we moved earlier into the top level root directory of our workspace.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/25474a42-7afa-4fce-8fe2-f3c1995540ac)

Then we update the `CodeUri` property in `./aws/cfn/ddb/template.yaml` to `cruddur-messaging-stream`: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/5bf7587b-6bc6-4b9f-a4b4-28ffedcaa91e)

We again run the `build` script and get the same results as before. Andrew confirms that this means the `CodeUri` property isn't relative to where the `template.yaml` file is located. We decide to create a new root level folder named `ddb`, then we move all of our DDB scripts, `template.yaml`, `config.toml`, our `cruddur-messaging-stream` folder containing `lamba_function.py`, and all other dependencies into the root level `ddb` folder. Next, we delete the `sam/ddb` folders from the root directory, as they're now empty.  

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/443fbb5b-7232-499a-b7b3-2a2681af5705)

We update the pathing to our variables in our `build`, `package`, and `deploy` scripts: 

```sh
FUNC_DIR="/workspace/aws-bootcamp-cruddur-2023/ddb/cruddur-messaging-stream/"
TEMPLATE_PATH="/workspace/aws-bootcamp-cruddur-2023/ddb/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/ddb/config.toml"
```

When we try our `build` script again, we find that it's creating an empty `cruddur-messaging-stream` folder within our existing one:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/45387f70-4897-4024-afcb-16afd2361391)

The `.aws-sam/build/ProcessDynamoDBStream` folder is also generated and empty still. We remove the created folders, and since we're getting prompts for it while running the `build` script, we add an empty `requirements.txt` file inside of the `cruddur-messaging-stream` folder. Then we run our `build` script again. It again creates the `cruddur-messaging-stream` folder inside the existing one. The empty `requirements.txt` we added made no difference either: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/c327ffb3-715c-4c6f-aa66-e9fa76a5f898)

We delete the duplicate `cruddur-messaging-stream` folder, rename the existing one to `function`, then updated the `FUNC_DIR` variable in our `build` script:

```sh
FUNC_DIR="/workspace/aws-bootcamp-cruddur-2023/ddb/function"
```

We then go back to the DDB `template.yaml` and update the `CodeUri` property again: 

```yaml
      CodeUri: .
```

From there, since it's not doing anything, we remove the `requirements.txt` file we created earlier from the `./ddb/function` directory that it resided in. We try our `build` script again and it completes. We know it worked because we have `lambda_function.py` in the `.aws-sam/build` directory: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/86527764-31b7-4554-93ea-c51cf12fecd1)

We continue on, running our `package` script. 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/5b76b920-1947-47cd-9641-cfac3bb4f0f2)

Before we run the `deploy` script, we check CloudFormation for the DDB stack:

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/686b9490-5dea-4da5-920d-0b611e13a965)

Since it never has completed successfully, we won't be able to run the `deploy` script yet. We delete the stack from CFN, THEN run the `deploy` script. Our changeset is created successfully.

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/f3e6bbf8-91a6-4b59-8e88-3566db2add51)

We execute the changeset from CloudFormation and wait for it to complete. The DDB stack shows a status of `CREATE_COMPLETE`. 

![end of SAM CFN Fix SAM Lambda Code Artifact createcomplete](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/77ea571d-04bd-4642-855a-e57aa8f98216)

This puts our DDB layer in a good state for now. We are now ready to move onto the CICD layer.

## CICD Layer

To start off the CICD layer, we start off with the script. We create a new one in the `./bin/cfn` directory named `cicd-deploy`, then copy the `networking-deploy` script to use as a basis. As always, we adjust the pathing for our `CFN_PATH` and `CONFIG_PATH` variables then update the `--s3-prefix` and `--tags group` flags to `--s3-prefix cicd \` and `--tags group="cruddur-cicd" \` respectively.

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/cicd/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/cicd/config.toml"

cfn-lint $CFN_PATH

BUCKET=$(cfn-toml key deploy.bucket -t $CONFIG_PATH)
REGION=$(cfn-toml key deploy.region -t $CONFIG_PATH)
STACK_NAME=$(cfn-toml key deploy.stack_name -t $CONFIG_PATH)

aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --s3-bucket $BUCKET \
    --s3-prefix cicd \
    --region $REGION \
    --template-file $CFN_PATH \
    --no-execute-changeset \
    --tags group="cruddur-cicd" \
    --capabilities CAPABILITY_NAMED_IAM
```

Next, we move over to the `./aws/cfn` directory and create a `cicd` folder, placing a new `template.yaml` and `config.toml` file in the folder. We populate `config.toml`, defining no parameters: 

```toml
[deploy]
bucket = 'jh-cfn-artifacts'
region = 'us-east-1'
stack_name = 'CrdCicd'
```

We next start implementing the `template.yaml`. We already know what parameters we're going to need, so we begin defining these:

```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: |
  - CodeStar Connection V2 Github
  - CodePipeline
  - CodeBuild
Parameters:
  GitHubBranch: 
    Type: String
    Default: prod
  GithubRepo: 
    Type: String
    Default: 'jhargett1/aws-bootcamp-cruddur-2023'
  ClusterStack:
    Type: String
  ServiceStack:
    Type: String
Resources: 
```

Its decided that we'd like to use a nested stack to implement the CICD layer. Andrew explains that when you have a `codebuild.yaml` file that you'd like to use over and over again, that's what you'd use, is a nested stack. I asked ChatGPT for further clarification: 

"By using a nested stack, you can modularize your CloudFormation template and separate different sets of resources into their own templates. This promotes reusability and maintainability, allowing you to manage and update individual components of your infrastructure independently."

We add the stack as a resource to our `template.yaml`: 

```yaml
Resources: 
  CodeBuildBakeImageStack:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-stack.html
    Type: AWS::CloudFormation::Stack
    Properties: 
      TemplateURL: nested/codebuild.yaml
```

With the `TemplateURL` defined, we go ahead and create the path by adding a new folder named `nested` to the `./aws/cfn/cicd` directory. Then we create the `codebuild.yaml` file inside. For our `codebuild.yaml` file, Andrew already as an existing one that works, so we copy this over, editing properties to match our project: 

```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: |
  Codebuild used for baking container images
  - Codebuild  Project
  - Codebuild Project Role
Parameters: 
  LogGroupPath:
    Type: String
    Description: "The log group path for CodeBuild"
    Default: "/cruddur/codebuild/bake-service"
  LogStreamName:
    Type: String
    Description: "The log group path for CodeBuild"
    Default: "backend-flask"    
  CodeBuildImage: 
    Type: String
    Default: aws/codebuild/amazonlinux2-x86_64-standard:4.0
  CodeBuildComputeType:
    Type: String
    Default: BUILD_GENERAL1_SMALL
  CodeBuildTimeoutMins:
    Type: Number
    Default: 5
  BuildSpec:
    Type: String
    Default: 'buildspec.yaml'
Resources: 
  CodeBuild:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-codebuild-project.html
    Type: AWS::CodeBuild::Project
    Properties:
      QueuedTimeoutInMinutes: !Ref CodeBuildTimeoutMins
      ServiceRole: !GetAtt CodeBuildRole.Arn
      # PrivilegedMode is needed to build Docker images
      # even though we have No Artifacts, CodePipeline Demands both to be set as CODEPIPLINE
      Artifacts:
        Type: CODEPIPELINE
      Environment:
        ComputeType: !Ref CodeBuildComputeType
        Image: !Ref CodeBuildImage
        Type: LINUX_CONTAINER
        PrivilegedMode: true
      LogsConfig:
        CloudWatchLogs:
          GroupName: !Ref LogGroupPath
          Status: ENABLED
          StreamName: !Ref LogStreamName
      Source:
        Type: CODEPIPELINE
        BuildSpec: !Ref BuildSpec
  CodeBuildRole:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-role.html
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Statement:
        - Action: ['sts:AssumeRole']
          Effect: Allow
          Principal:
            Service: [codebuild.amazonaws.com]
        Version: '2012-10-17'
      Path: /
      Policies:
        - PolicyName: !Sub ${AWS::StackName}ECRPolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Action:
                - ecr:BatchCheckLayerAvailability
                - ecr:CompleteLayerUpload
                - ecr:GetAuthorizationToken
                - ecr:InitiateLayerUpload
                - ecr:BatchGetImage
                - ecr:GetDownloadUrlForLayer
                - ecr:PutImage
                - ecr:UploadLayerPart
                Effect: Allow
                Resource: "*"
        - PolicyName: !Sub ${AWS::StackName}VPCPolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Action:
                - ec2:CreateNetworkInterface
                - ec2:DescribeDhcpOptions
                - ec2:DescribeNetworkInterfaces
                - ec2:DeleteNetworkInterface
                - ec2:DescribeSubnets
                - ec2:DescribeSecurityGroups
                - ec2:DescribeVpcs
                Effect: Allow
                Resource: "*"
              - Action:
                - ec2:CreateNetworkInterfacePermission
                Effect: Allow
                Resource: "*"
        - PolicyName: !Sub ${AWS::StackName}Logs
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Action:
                - logs:CreateLogGroup
                - logs:CreateLogStream
                - logs:PutLogEvents
                Effect: Allow
                Resource:
                  - !Sub arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:${LogGroupPath}*
                  - !Sub arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:${LogGroupPath}:*
Outputs:
  CodeBuildProjectName:
    Description: "CodeBuildProjectName"
    Value: !Sub ${AWS::StackName}Project
```

A lot of the properties defined here are quite self explanatory, but I'll dig a bit deeper here: 

`LogGroupPath`: Represents the log group path for CodeBuild. It allows you to specify the desired log group path where the CodeBuild logs will be stored.

`LogStreamName`: Represents the log stream name for CodeBuild. It allows you to specify the name of the log stream where the CodeBuild logs will be written. 

`CodeBuildImage`: Specifies the Docker image to be used for CodeBuild. 

`CodeBuildComputeType`: Specifies the compute type for CodeBuild. It determines the resources allocated to the CodeBuild project during the build process. 

`CodeBuildTimeoutMins`: This specifies the timeout duration for CodeBuild in minutes. If the build process exceeds this timeout, it will be terminated.

The `CodeBuildRole` we specified grants the necessary permissions to interact with ECR, VPC resources, and manage logs. Finally, the output provides access to the CodeBuild project name for further use in other parts of our infrastructure if needed. 

This should completely flesh out our `codebuild.yaml`. We move back over to our CICD `template.yaml` file and continue adding resources, starting with a CodeStar Connection. This resource is a service that will enable us to connect and manage resources in GitHub. 

```yaml
  CodeStarConnection:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-codestarconnections-connection.html
    Type: AWS::CodeStarConnections::Connection
    Properties: 
      ProviderType: GitHub
```

No properties to define here. `ProviderType` indicates we're building a CodeStar connection to connect us to our GitHub repository. 

We're now ready to begin working on the pipeline resource. We implement this in our CICD template, including all 3 stages; source, build, deploy:

```yaml
  Pipeline:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-codepipeline-pipeline.html
    Type: AWS::CodePipeline::Pipeline
    Properties: 
      RoleArn: !GetAtt CodePipelineRole.Arn
      Stages:
        - Name: Source
          Actions:
            - Name: ApplicationSource
              RunOrder: 1
              ActionTypeId:
                Category: Source
                Provider: CodeStarSourceConnection
                Owner: AWS
                Version: '1'
              OutputArtifacts:
                - Name: Source
              Configuration: 
                ConnectionArn: !Ref CodeStarConnection
                FullRepositoryId: !Ref GithubRepo
                BranchName: !Ref GitHubBranch
                OutputArtifactFormat: "CODE_ZIP"
        - Name: Build
          Actions: 
            - Name: BuildContainerImage
              RunOrder: 1
              ActionTypeId:
                Category: Build
                Owner: AWS
                Provider: CodeBuild
                Version: '1'
              InputArtifacts:
                - Name: Source
              OutputArtifacts:
                - Name: ImageDefinition
              Configuration:
                ProjectName: !GetAtt CodeBuildBakeImageStack.Outputs.CodeBuildProjectName
                BatchEnabled: false
        # https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-ECS.html                
        - Name: Deploy
          Actions:
            - Name: Deploy
              RunOrder: 1
              ActionTypeId: 
                Category: Deploy
                Provider: ECS
                Owner: AWS
                Version: '1'
              InputArtifacts: 
                - Name: ImageDefinition
              Configuration: 
                # In Minutes
                DeploymentTimeout: "10"
                ClusterName: 
                  Fn::ImportValue:
                    !Sub ${ClusterStack}ClusterName
                ServiceName: 
                  Fn::ImportValue:
                    !Sub ${ServiceStack}ServiceName                
```

Let me provide some information on the various properties of the stages: 

`RunOrder`: This property determines the order in which actions are executed within a stage.

`ActionTypeId`: This property identifies the type of action to be performed.

`Category`: This property specifies the category of the action. In this case, the category can be "Source", "Build", or "Deploy" depending on the stage.

`Provider`: This property specifies the provider of the action. For example, "CodeStarSourceConnection" for the source stage, "CodeBuild" for the build stage, and "ECS" for the deploy stage.

`Owner`: This property specifies the owner of the action. In this case, it is set to "AWS" indicating that the action is provided by AWS.

`Version`: This property specifies the version of the action.

`InputArtifacts`: This property specifies the input artifacts for the action. These artifacts are typically generated by previous actions in the pipeline.

`OutputArtifacts`: This property specifies the output artifacts produced by the action. These artifacts can be used as input by subsequent actions.

`Configuration`: This property contains the configuration settings for the action. The specific configuration properties depend on the action type.

For the `ServiceName` property, we are importing the value of the `ServiceName` property from our service layer. We need to go back to our service `template.yaml` and add this as an Output to export: 

```yaml
Outputs:
  ServiceName:
    Value: !GetAtt FargateService.Name
    Export:
      Name: !Sub "${AWS::StackName}ServiceName"
```

With this output added, we need to make it available to our CICD layer. We redeploy the service layer, running the `service-deploy` script. Then, we execute the changeset from CFN. The output is added: 

![image](https://github.com/jhargett1/aws-bootcamp-cruddur-2023/assets/119984652/dd7a03c7-4fb4-4f05-a7a2-33cfc6aa3890)

You may have also noticed we're already getting the ARN attribute from `CodePipelineRole` to define the value for `RoleArn` in the pipeline. We can now define this role in the CICD `template.yaml`. We also use the inline policy to define the permissions of the role, much as we've done a few times thus far: 

```yaml
  CodePipelineRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Statement:
        - Action: ['sts:AssumeRole']
          Effect: Allow
          Principal:
            Service: [codepipeline.amazonaws.com]
        Version: '2012-10-17'
      Path: /
      Policies:
        - PolicyName: !Sub ${AWS::StackName}EcsDeployPolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Action:
                - ecs:DescribeServices
                - ecs:DescribeTaskDefinition
                - ecs:DescribeTasks
                - ecs:ListTasks
                - ecs:RegisterTaskDefinition
                - ecs:UpdateService
                Effect: Allow
                Resource: "*"
        - PolicyName: !Sub ${AWS::StackName}CodeStarPolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Action:
                - codestar-connections:UseConnection
                Effect: Allow
                Resource:
                  !Ref CodeStarConnection
        - PolicyName: !Sub ${AWS::StackName}CodePipelinePolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Action:
                - s3:*
                - logs:CreateLogGroup
                - logs:CreateLogStream
                - logs:PutLogEvents
                - cloudformation:*
                - iam:PassRole
                - iam:CreateRole
                - iam:DetachRolePolicy
                - iam:DeleteRolePolicy
                - iam:PutRolePolicy
                - iam:DeleteRole
                - iam:AttachRolePolicy
                - iam:GetRole
                - iam:PassRole
                Effect: Allow
                Resource: '*'
        - PolicyName: !Sub ${AWS::StackName}CodePipelineBuildPolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Action:
                - codebuild:StartBuild
                - codebuild:StopBuild
                - codebuild:RetryBuild
                Effect: Allow
                Resource: !Join
                  - ''
                  - - 'arn:aws:codebuild:'
                    - !Ref AWS::Region
                    - ':'
                    - !Ref AWS::AccountId
                    - ':project/'
                    - !GetAtt CodeBuildBakeImageStack.Outputs.CodeBuildProjectName  
```

With this role, we're granting permissions for CodePipeline to perform tasks such as deploying ECS services, using CodeStar connections, accessing S3 buckets, managing CloudFormation stacks, and interacting with IAM roles and policies. It allows CodePipeline to describe and manipulate ECS services and task definitions, start and stop CodeBuild projects, and create and manage IAM roles.

We now need to go back and update our CICD `config.toml` to pass the parameters we added to our CICD `template.yaml`.

```toml
[deploy]
bucket = 'jh-cfn-artifacts'
region = 'us-east-1'
stack_name = 'CrdCicd'

[parameters]
ServiceStack = 'CrdSrvBackendFlask'
ClusterStack = 'CrdCluster'
GitHubBranch = 'prod'
GithubRepo = 'aws-bootcamp-cruddur-2023'
```

We might be ready to deploy. To test, we make our `cicd-deploy` script exectuable, then run it. 

