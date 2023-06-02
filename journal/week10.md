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
        - !Ref ALBSG
      Subnets: !Split [",", !ImportValue { "Fn::Sub": "${NetworkingStack}SubnetIds" }]
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

More details on the properties we're setting here:

`Type`:  Indicates the type of load balancer. In this case, it is set to application, which represents an application load balancer.

`IpAddressType`: Specifies the IP address type for the ALB. Here, it is set to `ipv4`, indicating the use of IPv4 addresses. It is the most common choice and allows the ALB to handle traffic over IPv4. The other option we could've selected is `dualstack`. This option specifies that the ALB should use both IPv4 and IPv6 addresses. It enables the ALB to handle traffic over both IPv4 and IPv6 protocols

`LoadBalancerAttributes`: Specifies a list of load balancer attributes and their corresponding values. Each attribute is represented as a dictionary with a Key and Value pair.

`Key: routing.http2.enabled`: Enables HTTP/2 routing for the ALB.

`Key: routing.http.preserve_host_header.enabled`: Disables preserving the host header for HTTP routing. When set to false, the host header is not preserved when forwarding requests to the target groups.

`Key: deletion_protection.enabled`: Enables deletion protection for the ALB. When deletion protection is enabled, the ALB cannot be deleted accidentally.

`Key: load_balancing.cross_zone.enabled`: Enables cross-zone load balancing. When enabled, the ALB evenly distributes traffic across all availability zones specified in the subnets property.

`Key: access_logs.s3.enabled`: Disables access logs to be stored in Amazon S3. When set to false, no access logs will be generated and stored.
