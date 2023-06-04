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
      ServiceName: backend-flask
      TaskDefinition: backend-flask
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

```
