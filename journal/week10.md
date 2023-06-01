# Week 10 — CloudFormation Part 1

We started off CloudFormation with a guest instructor Rohini Gaonkar, an AWS Sr. Dev Advocate leading instruction along with Andrew. We walked through setting up a basic CloudFormation template deploying an ECS Cluster. We also created a `deploy` script that deployed the cluster, along with a new S3 bucket named `jh-cfn-artifacts`.  In addition to this, we add a task to our `.gitpod.yml` file to install `cfn-lint`. Per ChatGPT, "`cfn-lint` is a tool used for linting CloudFormation templates, which checks for syntactical errors, best practices, and adherence to standards. It ensures the correctness and quality of the CloudFormation template."  

My main takeaway from this walkthrough to start our week off was that a lot of, if not most of what you will need to implement CloudFormation templates will be in the AWS documentation for it, which is quite vast. 

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

Per the snippet above, since we specified `AssignIpv6AddressOnCreation`, we must also specify `Ipv6CidrBlock`. Since neither is being used, we just remove the `AssignIpv6AddressOnCreation` property from our template. 
