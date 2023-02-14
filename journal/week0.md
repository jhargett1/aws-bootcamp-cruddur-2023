# Week 0 — Billing and Architecture
Week 0 - Homework Tasks:
### 1. Watched Week 0 - Live Streamed Video
I watched the live stream on Saturday, introducing all of us to the project, what a typical meeting for a potential project could look like, discussed LucidCharts and how to design a conceptual diagram of a project, as well as various other things. 

### 2. Watched Chirag's Week 0 - Spend Considerations
Watched along with Chirag's Week 0 video detailing access to the AWS billing console. For this lesson, I setup an alert if any service incurs a cost of $10. 

### 3. Watched Ashish's Week 0 - Security Considerations
Watched Ashish's introduction to Cloud Security and the what the goal is in cloud security. Things discussed in the video: 
* IAM User and how to create one
For this task, I created an IAM user
* Enabling MFA for IAM users
For this task, I enabled MFA on the IAM user account
* Accessing Cloudshell from the AWS Console
For this task, I followed along from the AWS Console
* AWS Regions
I watched along with the YouTube video.
* AWS Organizations and how to set them up
For this task, I setup my own AWS Organization.
* The usage of AWS CloudTrail
I followed along with the video.
* IAM Roles and tutorial
I followed along with the video.
* Enabling Organization SCP
For this task, I enabled Organization SCP
* SCP Best Practices
I followed along with the video.
* Top 5 security best practices
The top 5 security best practices are:
1. Data protection and residency in accordance to security policy
2. Identity and access management with least privilege
3. governance and compliance of AWS Services being used:
-global vs Regional Services
-Compliant Services
4. Shared Responsibility of Threat Detection
5. Incident Response PLans to include Cloud

### 4. Recreate Conceptual Diagram in Lucid Charts or on a Napkin
https://lucid.app/lucidchart/a23d495e-d367-4f7e-b41e-090b0e2e98a4/edit?viewport_loc=24%2C-218%2C2121%2C1002%2C0_0&invitationId=inv_626b6276-548c-4e72-8a1d-29598c13f588
![CruddurConceptualDiagram](https://user-images.githubusercontent.com/119984652/218616444-5ff352f4-008e-4585-a248-79383a33f0b5.png)

![ConceptualDiagramNapkin](https://user-images.githubusercontent.com/119984652/218879745-8d64950c-3fe7-4a0b-af40-0d4849909440.jpg)

### 5. Recreate Logical Architectual Diagram in Lucid Charts
https://lucid.app/lucidchart/42e9a5ef-bafe-4ff7-92e5-264c773c3829/edit?viewport_loc=-301%2C-46%2C3182%2C1504%2C0_0&invitationId=inv_53f96b63-6dae-4f9a-8a3d-637af5300228
![CruddurLogicalDiagram](https://user-images.githubusercontent.com/119984652/218616147-953b6451-4f05-4b82-ac96-87dd6f36830f.png)

### 6. Create an Admin User
In this task, I followed along with Andrew, creating a new Admin group through the AWS console, assigning AdministratorAccess permissions to the group. After this, I created a new IAM user named "BootCampUser" and added the user to the Admin group previously created. 
![BootCampUserCreation](https://user-images.githubusercontent.com/119984652/218816443-d89a6fae-9793-4694-9f29-e12213f83bc2.png)

### 7. Use CloudShell
We started this section by first accessing the AWS Console as the recently created IAM user. We access the cloudshell by clicking the icon for it in the top-right corner of the AWS Console. Once the cloudshell appears, we then ran a couple commands (personal information removed):

```
[cloudshell-user@ip-10-14-27-151 ~]$ aws --cli-auto-prompt
> aws sts get-caller-identity
{
    "UserId": "XXXXXXXXXXXXXXXXX",
    "Account": "XXXXXXXXXXX",
    "Arn": "arn:aws:iam::XXXXXXXXXXXX:user/BootCampUser"
```

### 8. Generate AWS Credentials
In this task, we navigated to the AWS Console, then IAM. We selected our newly created IAM user, clicked Security Credentials, then created a new access key, which was saved for later use. 
![AccessKeyCreation](https://user-images.githubusercontent.com/119984652/218829360-b2a981cd-c3c9-437b-9155-b2cf4e024b99.png)

### 9. Installed AWS CLI
In this task, Andrew walked us through the Amazon article for how to install or update the AWS CLI found here: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html . We also specified environment variables for the current bash terminal in Gitpod by adding the following code (information removed): 

```
export AWS_ACCESS_KEY_ID="xxxxxxxxxxxxxxxx"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxx"
export AWS_DEFAULT_REGION="us-east-1"
```

To show how we're doing this for the bootcamp, we instead go to the .gitpod.yml file and edit it with the code Andrew was able to provide us:

```
tasks:
  - name: aws-cli
    env:
      AWS_CLI_AUTO_PROMPT: on-partial
    init: |
      cd /workspace
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install
      cd $THEIA_WORKSPACE_ROOT
```

After this, Andrew indicated if we left GitPod, everything we've done here would be gone. It will not remember the environment variables we set. To keep them, we run more code to save them (information removed):

```
gp env AWS_ACCESS_KEY_ID="xxxxxxxxxxxxxxxx"
gp env AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxx"
gp env AWS_DEFAULT_REGION="us-east-1"
```

Andrew then walked us through how to make sure GitPod is storing the variables by opening https://gitpod.io then selecting your account in the top-right, then User Settings:

![GitPodVariables](https://user-images.githubusercontent.com/119984652/218862043-f3208679-8309-4eab-af3d-df67478b2476.png)

To finish up here, we committed the code to our GitHub repository on the main branch. We then checked through GitHub to make sure the changes are there: 

![GitHubCommitFromGitPod](https://user-images.githubusercontent.com/119984652/218864690-d5d061d0-7f6c-4dfd-b9ab-41922d660acc.png)

### 10. Create a Bill alarm

Andrew taught us how to create a bill alarm using the terminal as well. We started with an SNS topic. We followed along with the code he provided: 

```
aws sns create-topic --name billing-alarm
```

This created the sns topic. We then tweaked the existing code to subscribe to it (information removed):

```
    aws sns subscribe \
    --topic-arn="arn:aws:sns:us-east-1:XXXXXXXXXXXXX:billing-alarm" \
    --protocol=email \
    --notification-endpoint=joshhargett.jh@gmail.com
```

Andrew showed how to navigate through the AWS Console to find the subscription, pending confirmation. I then logged into my Gmail account, and confirmed the subscription:

![AlarmConfirmation](https://user-images.githubusercontent.com/119984652/218876229-caf278fe-ba4a-4ae3-9ad4-70c9b289398f.png)

After this, we then created the alarm_config file necessary for the alarm itself (information removed):

```
{
    "AlarmName": "DailyEstimatedCharges",
    "AlarmDescription": "This alarm would be triggered if the daily estimated charges exceeds 1$",
    "ActionsEnabled": true,
    "AlarmActions": [
        "arn:aws:sns:us-east-1:XXXXXXXXXX:billing-alarm"
    ],
    "EvaluationPeriods": 1,
    "DatapointsToAlarm": 1,
    "Threshold": 1,
    "ComparisonOperator": "GreaterThanOrEqualToThreshold",
    "TreatMissingData": "breaching",
    "Metrics": [{
        "Id": "m1",
        "MetricStat": {
            "Metric": {
                "Namespace": "AWS/Billing",
                "MetricName": "EstimatedCharges",
                "Dimensions": [{
                    "Name": "Currency",
                    "Value": "USD"
                }]
            },
            "Period": 86400,
            "Stat": "Maximum"
        },
        "ReturnData": false
    },
    {
        "Id": "e1",
        "Expression": "IF(RATE(m1)>0,RATE(m1)*86400,0)",
        "Label": "DailyEstimatedCharges",
        "ReturnData": true
    }]
  }
```

Then to run it:

```
aws cloudwatch put-metric-alarm --cli-input-json file://aws/json/alarm_config.json
```

We then committed the code to our repo. 

### 11. Create a Budget
For this task, Andrew walked us through the use of templates offered by AWS for creating a budget. Within our repo in GitPod, we created a new folder named "AWS" then a folder within that one named "json." From here, we created 2 new .json files, one for the budget itself and one for notifications. 

```
{
    "BudgetLimit": {
        "Amount": "10",
        "Unit": "USD"
    },
    "BudgetName": "Example Tag Budget",
    "BudgetType": "COST",
    "CostFilters": {
        "TagKeyValue": [
            "user:Key$value1",
            "user:Key$value2"
        ]
    },
    "CostTypes": {
        "IncludeCredit": true,
        "IncludeDiscount": true,
        "IncludeOtherSubscription": true,
        "IncludeRecurring": true,
        "IncludeRefund": true,
        "IncludeSubscription": true,
        "IncludeSupport": true,
        "IncludeTax": true,
        "IncludeUpfront": true,
        "UseBlended": false
    },
    "TimePeriod": {
        "Start": 1477958399,
        "End": 3706473600
    },
    "TimeUnit": "MONTHLY"
  }
```

<sub>This code above is for the budget itself, set to $10.</sub>

```
[
    {
        "Notification": {
            "ComparisonOperator": "GREATER_THAN",
            "NotificationType": "ACTUAL",
            "Threshold": 80,
            "ThresholdType": "PERCENTAGE"
        },
        "Subscribers": [
            {
                "Address": "joshhargett.jh@gmail.com",
                "SubscriptionType": "EMAIL"
            }
        ]
    }
  ]
  <sub>This code is for the notifications.</sub>
```

The code to create the budget is here:

```
aws budgets create-budget \
    --account-id 123456789 \
    --budget file://aws/json/budget.json \
    --notifications-with-subscribers file://aws/json/budget-notifications-with-subscribers.json
```

Andrew then showed us how to store our account id as an environmental variable(information changed):

```
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
gp env AWS_ACCOUNT_ID="XXXXXXXXXXX"
```

We then store the variable in the budget creation code: 

```
aws budgets create-budget \
    --account-id $AWS_ACCOUNT_ID \
    --budget file://aws/json/budget.json \
    --notifications-with-subscribers file://aws/json/budget-notifications-with-subscribers.json
```

I checked through the AWS Console to see if the "Example Tag Budget" is added. It is:

![ExampleTagBudget](https://user-images.githubusercontent.com/119984652/218873676-b6b55342-738d-4d52-9a8c-48676118592d.png)

