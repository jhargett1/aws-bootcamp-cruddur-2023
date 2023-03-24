# Week 5 — DynamoDB and Serverless Caching

We started off by adding boto3 to requirements.txt.Then we cd'd to backend-flask. Ran pip install -r requirements.txt from terminal. We then got our environment up and running by performing a docker-compose up. While Docker was composing, we created 2 new folders in backend-flask/bin: db and rds. We then moved all the db- batch scripts to db folder then removed "db-" from name to tidy up. Next we moved rds-update-sg-rule to rds folder and removed "rds". I then created a new folder in backend-flask/bin named ddb for DynamoDB stuff. Andrew announced that we're going to use DynamoDB using the SDK. 

We created new files in ddb folder: drop, schema-load, seed. We made schema-load executable by running chmod u+x bin/ddb/schema-load. From there, we copied in create table code from AWS Boto3 documentation. It wasn't perfect, so we adjusted code for schema. Once we completed schema-load, from the terminal, I ran ./bin/ddb/schema-load and received an error.

![clientnotdefinedWeek5](https://user-images.githubusercontent.com/119984652/227646578-b16d95aa-610c-4422-9254-62ddf9bb674e.png)

Once we fixed the error in code, we then ran schema-load again. This time, DynamoDB was not running. We commented out DynamoDB last week in our docker-compose.yml to save on compute. We go back into docker-compose.yml and remove the comments, then docker-compose up again. After compose up, ran schema-load again, and it created our local DynamoDB table.

![dynamodbschemaloadWeek5](https://user-images.githubusercontent.com/119984652/227646651-4a444484-0698-437d-a778-97649a2719de.png)

We need a way to show what we have. Created new file in ddb named list-tables. After working on list-tables, created drop in ddb folder as well as seed. Finished with drop and tested, we successfully dropped our table. Worked on seed file, made file executable. What do we want to do with seed? We want to implement our access patterns and seed data. Began working on ddb/seed, and Andrew went through the code, line by line showing us what it's doing. After completing ddb/seed, we again try running it, but find we have no table. We reloaded ddb/schema-load, then list-tables.

![schemaloadlisttablesWeek5](https://user-images.githubusercontent.com/119984652/227646725-36833365-b03a-468a-9f64-a306d064bc5b.png)

Then, we again ran ddb/seed, this time it seeded data. We want to see the data we're seeding, so in ddb, we create scan and set it for local DynamoDB only, as Andrew said doing a scan in production can be expensive. Created new folder in ddb named patterns, then created 2 new files: get-conversation and list-conversations. These allow us to begin implementing our access patterns. We first complete get-conversation, make it executable, then run it. This is similar to a scan, but we're returning information that we queried and limiting the results. In list-conversations, we began another our of access patterns. Andrew goes through explaining the information we're querying here as well, then we test. While testing, we go back to db.py in backend-flask/lib and update all instances of print_sql to pass the params we set while refining our queries for mock data.

![listconversationsWeek5](https://user-images.githubusercontent.com/119984652/227646788-3957e279-6844-4c32-a631-a018697e12b6.png)

From there, we added an install snippet for backend-flask to .gitpod.yml, also we updated our psql command in ddb/drop to drop the database IF EXISTS. We created ddb.py in backend-flask/lib, and began implementing code to it. Andrew showed us the difference between the Postgres database in db.py and what we're implementing in ddb.py. In the Postgres database, we are doing initialization, using a constructor to create an instance of the class, and in ddb.py it's a stateless class. Andrew said if you can do things without state, it's much easier for testing, as you just test the inputs and outputs, using simple data structures.

![ddbvspgdbWeek5](https://user-images.githubusercontent.com/119984652/227646954-5af77b18-9600-4884-883c-3e60222d77f1.png)

In fixing the hardcoded values of user_handle from last week, Andrew has us create a new folder in backend-flask/bin named cognito, then a new file in the folder named list-users. Prior to beginning, reverted changes made to fix hardcoded values before that were suggested initially by anle4s#7774. Instead, replaced hardcoded 'user_handle' value with my own username "joshhargett" in app.py under the /api/activities route. To list Cognito users through the AWS CLI, we need the user pool id. From terminal, we run the following: aws cognito-idp list-users --user-pool-id=us-east-1_N7WWGl3KC this returns our data.

![getuserawscliWeek5](https://user-images.githubusercontent.com/119984652/227647007-cb43b585-118f-45e1-b988-1b09cf69e717.png)

After coding list-users, Andrew again began explaining what the code meant. First we needed to store the env var for the AWS_COGNITO_USER_POOL_ID. From terminal, I ran 'env | grep COGNITO' to see if I had the variable stored already. I did not. To store it, from terminal I then ran:

```
export AWS_COGNITO_USER_POOL_ID="us-east-1_N7WWGl3KC"
gp env AWS_COGNITO_USER_POOL_ID="us-east-1_N7WWGl3KC"
```

I made sure I had the variable stored as well.

![grepcognitoWeek5](https://user-images.githubusercontent.com/119984652/227647102-1394c4be-70ae-407c-b323-f44397cc6dbd.png)

Next, from docker-compose.yml, I updated AWS_COGNITO_USER_POOL_ID to use the variable I just saved too. After Andrew explained list-users, we made the file executable. Then we ran the file.

![listuserscognitoWeek5](https://user-images.githubusercontent.com/119984652/227647224-63f584dc-acaa-4561-a9d1-f4f6f6af8cb0.png)

We next moved onto a file to update our users cognito user id in our database. In bin/db we create update_cognito_user_ids. We then implement the code for this. Andrew talks us through what the file is doing through the code. The sql command is updating our public.users table setting the cognito user id based on the sub we passed in. We then run a query commit to execute it. Further down in the code, we're doing the same thing that we did in list-users, but instead of printing the data, we're returning it. Before we can do that, we have to seed our data. We add a path to our setup file for update_cognito_user_ids. We run ./bin/db/setup, but get an error on that path, so instead we run update_cognito_user_ids after running db/setup. We're not returning the information we wanted, so we access db.py and find our query_commit definition. We were missing params from being passed, so we added it, then back in terminal ran the script again. This time, it returned the information we wanted.

![updatecognitouseridsparamsWeek5](https://user-images.githubusercontent.com/119984652/227647264-81f870fd-bfe8-4cd6-8320-fba9601b4c88.png)

After encountering the error on the setup script, we comment out our variable for our production environment in docker-compose, then remove the comment line from our local Postgres database instead. We then do a Docker compose down, and then back up again. 

We then edited our definition of data_message_groups in app.py by using some code from our /api/activities/home route. After this, we next moved on to replace the mock data we had in message_groups.py and replaced it with a query to our Dynamo DB. The query is non-existant currently, so we must go and create it. For this, we created a new folder inside backend-flask/db/sql named users, then a new SQL file named uuid_from_handle.sql. After this, we updated HomeFeedPage.js, MessageGroupsPage.js, MessageGroupPage.js, and MessageForm.js to include authorization headers we just created. From our app, we're logged in, and go to the Messages section. It does not return data. Through the Inspect tool of Chrome, we troubleshoot errors in code, eventually connecting to our local Postgres database. We can see our query running from the backend-flask logs.

![backendlogsWeek5](https://user-images.githubusercontent.com/119984652/227647357-c11a04fc-7b08-4280-aae7-59442f75ae75.png)

But if we connect to our Postgres database and run a query selecting all from users, our cognito_user_id is not being passed.

![cognitouseridnotpassedWeek5](https://user-images.githubusercontent.com/119984652/227647386-a4ed917b-aab3-48e6-a36e-9c083d7b7c9e.png)

After some troubleshooting, we find that it IS actually passing the cognito_user_id. 

Moving on we pulled CheckAuth and defined it in it's own file, CheckAuth.js. We updated our HomeFeedPage.js, MessageGroupsPage.js, MessageGroupPage.js, and MessageForm.js to use setUser, which we defined in CheckAuth. We also removed the previous code for checkAuth. After further testing, we still find we're not returning data from the Messages page. Eventually we find that we need to add our AWS_ENDPOINT_URL variable to our docker-compose.yml file.

![awsendpointdockerWeek5](https://user-images.githubusercontent.com/119984652/227647462-f9b2d6a1-e7e1-4866-807a-e327cac1decc.png)

After we compose down and back up, there's now Message data, at least for Andrew. I ended up needing to go back through once again, updating the ddb/seed file to include just andrewbrown and bayko. After this, I was combing through my ddb.py file and noticed that I had forgotten to return results. Once I fixed this, I still was not receiving messages, but I was getting 200's in the backend-flask log as well as no errors when running the Inspect tool. My suspicion is since the mock conversation data is hardcoded values between 'andrewbrown' and 'bayko', this is why I do not see the messages. Back on task, we next updated App.js for our path for the MessageGroupPage. Instead of going to a static @:handle, it's now dependent upon the message_group_uuid.

![message_group_uuidWeek5](https://user-images.githubusercontent.com/119984652/227647515-0f274558-875f-4214-868a-a8a8ad22988a.png)

We updated this in our MessageGroupPage.js file. 

We next moved onto making our message group definition a little more strict. In ddb.py, we updated the KeyConditionExpression with what we listed in our get-converstation.py file. We removed the hardcoded value of the year, and instead passed datetime.now()year as year. This failed, so we ended up having to put the value into a string, like so: year = str(datetime.now().year). We moved onto updating the same value in list-conversations.py as well. After refreshing, the data is again showing in the Messages section, but it's listing the @handle as the page. We go into our MessageGroupItem.js file and pass out message_group_uuid for /messages/. We also needed to update our const classes to pass the message_group_uuid as well. A quick refresh to our web app, and there's no errors, but the messages are not displaying. Andrew notes this is because it's part of the query we need on the MessageGroupPage.js. We check our const loadMessageGroupData, and it's already passing the message_group_uuid. We need to start implementing this into our backend. 

In app.py, we remove the hardcoding of user_sender_handle and update our def data_messages to pass message_group_uuid as well. (removedhardcodingWeek5) We then updated this again, this time checking for cognito_user_id and message_group_uuid. In messages.py, we updated the code to pass in the message_group_uuid called client, then it will list messages. In ddb.py, we add define a function for list_messages passing client and the message_group_uuid as well.

We previously added code to get the cognito_user_id in message_groups.py, so we add this code to messages.py as well. This is not being used now, but it's for permissions checks we will implement later. 

After updating all of this, we again go back and refresh our Messages page and return a 404 error. It doesn't know where the routes are going. We go back and check our app.route, and it appears to be valid, but we missed removing an @ symbol earlier. Another refresh, and now we're getting a 401 error, we had forgotten to add an authentication header to a section of code in our MessageGroupPage.js, so we go back and add it. After this, we again refresh our web app. db is not defined now. In messages.py, we import db from lib.db then refresh again and get a credential_provider error. Andrew explains sometimes this is just a Gitpod specific error and doing a refresh will make it work. It does in this case, we receive a "NoneType" object is not scriptable error now. To remedy, we go into our app.py, and find that we left off a return statement. Once added, and another refresh, now we have messages showing. The mock messages however, are in the wrong order. To fix this, we had to reverse the items in our code. In ddb.py, we added items.reverse() to our code, then from did the same from our ddb/patterns/get-conversations file as well. For our conversations, we need to be able to differentiate between starting a new conversation and contiuing an existing one. To do this, we added a conditional if statement with an else passing along either the handle (new conversation) or message_group_uuid(existing conversation).

![conditionalstatementWeek5](https://user-images.githubusercontent.com/119984652/227647674-b72f9ad9-d5ae-4e4e-94d1-44476c19e42f.png)

In app.py, we need to adjust what we have for a create function. Under the definition for data_create_message, we again remove the hardcoding for the user_handle, then pass the same code we previously passed, this time passing the message, message_group_uuid, cognito_user_id, and the user_receiver_handle. We also needed to update our variables for message_group_uuid and user_receiver_handle to request.json and get the message_group_uuid and handle. Additionally we added an if else statement indicating if the message_group_uuid is None, we're creating a new message. If it is not, we're doing an update. Essentially similar to what we did earlier in ddb.py. Since we're still working on existing messages, we comment out the create elif statement for now. 

Back in ddb.py, we update our code to define our create_message function here as well. It will generate the uuid for us, since DynamoDB cannot by itself, it will create a record with message_group_uuid, message, message_uuid, amongst more information.

![recordWeek5](https://user-images.githubusercontent.com/119984652/227647763-5a1a27b3-79c1-4a34-9155-01b2f30a7602.png)

When we refresh our web app again, we're not getting errors from the backend logs, but upon using Inspect from our browser, it's giving TypeError: Cannot set property json of Object which has only a getter.

![typeerrorWeek5](https://user-images.githubusercontent.com/119984652/227648017-3455fddc-4d4f-43e1-9b06-c49d4d456fdd.png)

We jump back over create_message.py and find we have a template added that we need to create. We go into backend-flask/db/sql/users directory and create create_message_users.sql.

![createmessageusersWeek5](https://user-images.githubusercontent.com/119984652/227648066-2ef72119-8d06-46e5-980b-1dc65e2d1132.png)

When we refresh our web app this time, it will now post messages(data) correctly.

![CreateActionWorkingWeek5](https://user-images.githubusercontent.com/119984652/227648160-ca5e9757-d90a-4af6-a940-0042957c3164.png)

Now that that is working as intended, we now go back and focus on creating a new conversation. In frontend-react, we navigate to src/App.js and add a new path for a new page, MessageGroupNewPage. We then add the import to the top of the page as well. We then move over to src/pages and create the new page, MessageGroupNewPage.js. In this page, we import CheckAuth, then remove the function and pass our setUser. 
We then create a 3rd mock user for our database to our seed.sql file in backend-flask/db. So we don't have to compose down our environment and then compose it back up, instead we pass the SQL query locally through the terminal after connecting to our Postgres db using ./bin/db/connect, then running our query of manually.

![querymanuallyWeek5](https://user-images.githubusercontent.com/119984652/227648338-88043d65-16ad-4413-934c-98e8063fee16.png)

In app.py we define a new function data_users_short passing in the handle. We need to create a new service for this. In backend-flask/services we create a new one, users_short.py. (usershortWeek5) We then go into our sql/users and create a new file called short.sql.

![shortsqlWeek5](https://user-images.githubusercontent.com/119984652/227648822-7a74f9bc-8743-4ab4-adc8-ab81ccfa0893.png)

Also in frontend-react/components we create MessageGroupNewItem.js. We also have to go back and update MessageGroupFeed.js. A refresh of our web app, and we have another conversation. In MessageForm.js, we add a conditional to create messages and then we uncomment the lines of code we previously commented out in create_message.py to imlement it. In ddb.py, we then define the create_message_group function utilizing batch write and import botocore.exceptions as well. 

We needed to create a Dynamo DB Stream trigger so as to update the message groups. This is needed so we can use our production Dynamo DB as opposed to our local one. To start this, we ran ./bin/ddb/schema-load prod. We then logged into AWS and checked DynamoDB to see our new table.

![dynamodbtableWeek5](https://user-images.githubusercontent.com/119984652/227649604-66f25e54-c1a9-4e20-a120-a14006bec79a.png)

We next needed to turn on streaming through the console.  To do this, we went to Tables > Exports and streams > Turn on. We finalized this by selecting New Image.

![newimageWeek5](https://user-images.githubusercontent.com/119984652/227649768-67b19719-3313-4609-8f90-f4e9a011543e.png)

We next needed to create a VPC endpoint for the DynamoDB service, but had concerns as it may cost money. We looked into it and gateway endpoints, which are whats used for connecting to DynamoDB, do not incur additional charges. Created VPC endpoint in AWS named ddb-cruddur1 then connected it to DynamoDB as a service.

![ddbcruddur1Week5](https://user-images.githubusercontent.com/119984652/227649929-88197238-2bba-479c-9536-18bcad873864.png)

From here, we needed to create a Lambda function to run for every time we create a message in Cruddur (our web app). While reviewing the Lambda code to create the trigger, Andrew made note that it's recreating the message group rows with the new sort key value from DynamoDB. This is because in DynamoDB, we cannot update these values. They must be removed and recreated.

![sksortkeyWeek5](https://user-images.githubusercontent.com/119984652/227650189-c94084c3-9552-4886-8da2-a4220e93d0f5.png)

From the AWS console, we navigate to Lambda, then create a new trigger named cruddur-messageing-stream, using Python 3.9 runtime, and x86_64 architecture. For the execution role, we granted it a new role with Lambda permissions. We then enabled the VPC and selected our pre-existing one we configured last week, then selected "Create." We already had the code written out, so we copy/paste the code into "Code" of our function in the AWS console.

![lambdacodeWeek5](https://user-images.githubusercontent.com/119984652/227650481-60e81151-7206-4a15-92da-36803f3b6df6.png)

From here we went to Configuration > Permissions to set IAM role permissions for the function. We ran into a few snags during this process, as the pre-existing policies in AWS did not give us the role permissions we needed for our function to operate correctly. We found that we had not yet added our GSI (Global Secondary Indexes) to our db yet, so we deleted the DynamoDB table we created moments ago in AWS, then edited our ddb/schema-load file to include the GSI.

![globalsecondaryindexes](https://user-images.githubusercontent.com/119984652/227650740-4c775542-1c73-4b13-980a-9a9e89248a08.png)

Once the code was added to our ddb/schema-load file, we again ran ./bin/ddb/schema-load prod from terminal to recreate our table inside AWS DynamoDB. Next, we went back through and again turned on stremaing, setting stream details to New image. We circled back to VPC just to make sure that setup is still configured, it was. Now we assign the trigger we created earlier to our table. 

![triggermessagestreamWeek5](https://user-images.githubusercontent.com/119984652/227650982-96f24e0d-ac00-4e5e-922b-11355d3af0d3.png)

Now all we need to do is make our web app use production data. We went back over to docker-compose.yml and commented out the AWS_ENDPOINT_URL variable we had set previously. 

After that, we then composed up our environment, and began testing the function. We navigated to the Messages page, and my attempts to send a message did not work, yet Andrew's did. We viewed the Cloudwatch logs, and Andrew was getting errors, whereas my log was blank because the Lambda did not run. Due to the errors received in the Cloudwatch logs, we continued on with the permissions issue I had mentioned before in regards to the IAM role permissions of the Lambda function. We removed the existing IAM role we assigned, then created a new inline policy granting our Lambda access to DynamoDB, giving it query, deleteitem, and putitem actions. Next we specified our ARNs for our resources, created a new folder inside our aws folder, then created a new json file named cruddur-messaging-stream and pasted the json from the policy we just created. We then added our Lambda code to our repository as well. For our policy, we then named it cruddur-messaging-stream-dynamodb and saved it. With the new policy enabled, we tested again, then went back to the Cloudwatch logs. Andrew's Cloudwatch logs again gave errors, mine was blank, as the Lambda still had not run. I continued on, updated the Lambda along with Andrew, deployed the changes, then again tested the web app. More errors to work through. As it turned out, we were returning a record of events removed. We edited the Lambda again, this time adding a conditional that if the event is a remove event, we will return early.

![returnearlyWeek5](https://user-images.githubusercontent.com/119984652/227651332-a23181b0-ccd1-4af8-9fd8-f324379e8bfe.png)

Once this was added and deployed to our Lambda function, we tested again, then again reviewed the Cloudwatch logs. There were no more errors reported. After this, I went back through my code once again. I once more updated my seed.sql file, removing Andrew's mock data and instead inserting my own. From here, I committed my code, composed down, stopped my Gitpod workspace, then relaunched a new one. From there, I composed back up, and ran ./bin/db/setup. This created my local Postgres db again, this time seeding different data than before. The last portion of db/setup ran update_cognito_user_ids, which swapped out the mock Cognito user id and replaced it with my RDS one. After this, I deleted my DynamoDB table a 3rd time, recreated it, completing all of the same steps we had previously. Then, I launched the web app and signed in. After this, I was now able to create messages!

![cruddurstreamcloudwatchlogWeek5](https://user-images.githubusercontent.com/119984652/227651366-70bca9a5-56f8-4f25-80ce-3e3147c07396.png)

For Security Considerations this week, I again kept detailed notes: 

```
Week 5 Notes Security Considerations – 

Amazon DynamDB – What is it and how does it work? 
DynamoDB use cases by industry: Customers rely on DynamoDB to support their mission-critical workloads
-	Banking and finance
o	Fraud detection
o	User transactions
o	Mainframe offloading
-	Gaming
o	Game states
o	Leaderboards
o	Player data stores
-	Software and Internet
o	Metadata caches
o	Ride-tracking data stores
o	Relationship graph data stores
-	Ad tech
o	User profile stores
o	Metadata stores for assets
o	Popular-item cache
-	Retail
o	Shopping carts
o	Workflow engines
o	Customer profiles
-	Media and Entertainment
o	User data stores
o	Media metadata stores
o	Digital rights management stores
Security Best Practices – AWS side
-	Use VPC Endpoints: Use Amazon Virtual Private Cloud (VPC) to create a private network from your application or Lambda to a DynamoDB. This helps prevent unauthorized access to your instance from the public internet
-	Compliance standard is what your business requires
-	Amazon DynamoDB should only be in the AWS region that you are legally allowed to be holding user data in
-	Amazon Organizations SCP – to manage DynamoDB table deletion, DynamoDB creation, region lock, etc
-	AWS CloudTrail is enabled and monitored to trigger alerts on malicious DynamoDB behavior by an identity in AWS
-	AWS Config Rules (as no GuardDuty even in March 2023) is enabled in the account and region of DynamoDB

Security Best Practices – application side
-	DynamoDB to use appropriate Authentication – use IAM roles/AWS Cognito Identity Pool – avoid IAM users/groups
-	DynamoDB User Lifecycle Management – create, modify, delete users
-	AWS IAM roles instead of individual users to access and manage DynamoDB
-	DAX Service (IAM) Role to have Read Only Access to DynamoDB (if possible)
-	Not have DynamoDB be accessed from the internet (use VPC endpoints)
-	Site to site VPN or Direct Connect for Onprem and DynamoDB Access
-	Client side encryption is recommended by Amazon for DyanmoDB

```
