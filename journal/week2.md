# Week 2 — Distributed Tracing

## Watch Week 2 Live-Stream Video

Followed along with Jessica and Andrew as we added installation instructions by adding the following files to our 'requirements.txt'

```
opentelemetry-api 
opentelemetry-sdk 
opentelemetry-exporter-otlp-proto-http 
opentelemetry-instrumentation-flask 
opentelemetry-instrumentation-requests
```
Jessica also guided us and Andrew through Honeycomb, including accessing our API key. We then ran the export and gp env commands for our HONEYCOMB_API_KEY and our HONEYCOMB_SERVICE_NAME to store the variables. We then installed the dependencies from the console:

```
pip install -r requirements.txt
```

We then added the following to 'backend-flask/app.py' :

```python
# HoneyComb ---------
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# HoneyComb -----------
# Initialize tracing and an exporter that can send data to Honeycomb
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)
```

Then below :

```python
# Initialize automatic instrumentation with Flask
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()
```
## Instrument Honeycomb with OTEL

We then needed to add environment variables to `backend-flask` in our docker-compose.yml file to match up with the variables we added earlier: 

```yml
OTEL_SERVICE_NAME: 'bakend-flask'
OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"
```

Additionally, Andrew then showed us how to configure the ports for the frontend and backend to remain open(public) by adding port information to our gitpod.yml file:

```yml

ports:
  - name: frontend
    port: 3000
    onOpen: open-browser
    visibility: public
  - name: backend
    port: 4567
    visibility: public
  - name: xray-daemon
    port: 2000
    visibility: public
```
I was running into 401 errors, so I adjusted the OTEL_SERVICE_NAME variable in the docker-compose.yml file:

```yml
OTEL_SERVICE_NAME: 'backend-flask' # it was 'bakend-flask' previously. Just a typo.
```

The work I'd completed in weeks previous to the Dockerfile in 'frontend-react-js' to fix the npm install issue was now causing issues with my app loading correctly, so I reverted it back to what we had previously:

```dockerfile
FROM node:16.18

ENV PORT=3000

COPY . /frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
EXPOSE ${PORT}

CMD ["npm", "start"]
```
We also updated the 'app.py' file again with additional code to import the ConsoleSpanExporter and the SimpleSpanProcessor:

```python
from opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor


# Show this in the logs within the backend-flask app (STDOUT)
simple_processor = SimpleSpanProcessor(ConsoleSpanExporter())
provider.add_span_processor(processor)

```

## Instrument X-Ray

We added the X-Ray Daemon (Andrew kept pronouncing it "day-mon" which is how I had thought it was pronounced too, but he said it's actually pronounced "dee-mon" lol) and defined environment variables for X-Ray in our 'docker-compose.yml' file: 

```yml
version: "3.8"
services:
  xray-daemon:
    image: "amazon/aws-xray-daemon"
    environment:
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      AWS_REGION: "${AWS_REGION}"
    command:
      - "xray -o -b xray-daemon:2000"
    ports:
      - 2000:2000
```

```yml
  backend-flask:
    environment:
      FRONTEND_URL: "https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      AWS_XRAY_URL: "*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*"
      AWS_XRAY_DAEMON_ADDRESS: "xray-daemon:2000"
```

We adjusted our 'backend-flask/services/home_activities.py' file to add spans and attributes:

```python
from datetime import datetime, timedelta, timezone
from opentelemetry import trace

tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run():

    with tracer.start_as_current_span("home-activites-mock-data"):
      span = trace.get_current_span()
      now = datetime.now(timezone.utc).astimezone()      
      span.set_attribute("app.now", now.isoformat())
      results = [{
        'uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
        'handle':  'Andrew Brown',
        'message': 'Cloud is very fun!',
        'created_at': (now - timedelta(days=2)).isoformat(),
        'expires_at': (now + timedelta(days=5)).isoformat(),
        'likes_count': 5,
        'replies_count': 1,
        'reposts_count': 0,
        'replies': [{
          'uuid': '26e12864-1c26-5c3a-9658-97a10f8fea67',
          'reply_to_activity_uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
          'handle':  'Worf',
          'message': 'This post has no honor!',
          'likes_count': 0,
          'replies_count': 0,
          'reposts_count': 0,
          'created_at': (now - timedelta(days=2)).isoformat()
        }],
      },
      {
        'uuid': '66e12864-8c26-4c3a-9658-95a10f8fea67',
        'handle':  'Worf',
        'message': 'I am out of prune juice',
        'created_at': (now - timedelta(days=7)).isoformat(),
        'expires_at': (now + timedelta(days=9)).isoformat(),
        'likes': 0,
        'replies': []
      },
      {
        'uuid': '248959df-3079-4947-b847-9e0892d1bab4',
        'handle':  'Garek',
        'message': 'My dear doctor, I am just simple tailor',
        'created_at': (now - timedelta(hours=1)).isoformat(),
        'expires_at': (now + timedelta(hours=12)).isoformat(),
        'likes': 0,
        'replies': []
      }
      ]
      span.set_attribute("app.result_length", len(results))   
      return results               
```
We weren't getting data, so we had to adjust 'backend-flask/app.py'

```python
# Show this in the logs within the backend-flask app (STDOUT)
simple_processor = SimpleSpanProcessor(ConsoleSpanExporter())
provider.add_span_processor(simple_processor)
```

To circle back to original issue I encountered and fixed, Andrew provided further instruction to automatically run npm install from our environment upon start up of the workspace. To do so, we added instruction to our 'gitpod.yml' file: 

```yml
  - name: react-js
    command: |
      cd frontend-react-js
      npm i
```
To begin instrumenting X-Ray, we had to setup X-Ray resources. From our 'aws' folder, we created a 'json' folder, then an 'xray.json' file within. We then setup our resources in the file: 

```json
{
  "SamplingRule": {
      "RuleName": "Cruddur",
      "ResourceARN": "*",
      "Priority": 9000,
      "FixedRate": 0.1,
      "ReservoirSize": 5,
      "ServiceName": "backend-flask",
      "ServiceType": "*",
      "Host": "*",
      "HTTPMethod": "*",
      "URLPath": "*",
      "Version": 1
  }
}
```

We call X-Ray in our 'backend-flask/app.py' file: 

```python
# X-RAY -----------
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

```

```python
# X-RAY -----------
xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service='backend-flask', dynamic_naming=xray_url)
XRayMiddleware(app, xray_recorder)

```
We must also add instruction for it in 'requirements.txt' : 

```
aws-xray-sdk
```

As a good practice learned from Jessica, we hardcoded the region in our 'docker-compose.yml' file instead of using a variable: 
```yml
      AWS_REGION: "us-east-1"
```
We ran 'pip install -r requirements.txt' to reinstall Python dependencies, and found again we needed to adjust 'backend-flask.py' : 

```python
# X-RAY -----------
xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service='backend-flask', dynamic_naming=xray_url)
# We removed this line ---------- XRayMiddleware(app, xray_recorder) 



app = Flask(__name__)

# X-RAY -----------
XRayMiddleware(app, xray_recorder) # and replaced it beneath app

```

This got X-Ray working. We added segments and subsegments to our 'backend-flask/services/user_activities.py' file:

```python
from aws_xray_sdk.core import xray_recorder
```

```python
    # xray -------
    segment = xray_recorder.begin_segment('user_activities')

```

```python

    subsegment = xray_recorder.begin_subsegment('mock-data')
    # xray -------
    dict = {
      "now": now.isoformat(),
      "results-size": len(model['data'])   
    }    
    subsegment.put_metadata('key', dict, 'namespace')

```

## Configure custom logger to send to CloudWatch Logs

In this additional video, Andrew showed us how to implement Cloudwatch Logs. We added instructions to 'requirements.txt' : 

```
watchtower
```

In our 'backend-flask/app.py' file, we implemented Cloudwatch: 

```python
# Cloudwatch logs ----
import watchtower
import logging
from time import strftime

# Configuring Logger to Use CloudWatch
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
cw_handler = watchtower.CloudWatchLogHandler(log_group='cruddur')
LOGGER.addHandler(console_handler)
LOGGER.addHandler(cw_handler)
LOGGER.info("test log")
```

```python
@app.after_request
def after_request(response):
    timestamp = strftime('[%Y-%b-%d %H:%M]')
    LOGGER.error('%s %s %s %s %s %s', timestamp, request.remote_addr, request.method, request.scheme, request.full_path, response.status)
    return response
```

We then added something to gain data to our 'backend-flask/services/home_activities.py' file: 

```python
class HomeActivities:
  def run():

   logger.info("HomeActivities")
    with tracer.start_as_current_span("home-activites-mock-data"):
      span = trace.get_current_span()
      now = datetime.now(timezone.utc).astimezone()  
```

We also went through and commented out our code for X-Ray so it would not throw errors. After Andrew showed us how Cloudwatch worked, we then went back and commented out our Cloudwatch code as well, so as to not incur additional cost when spinning up our environment. 

## Integrate Rollbar and capture and error

In this lesson, we started with Rollbar by adding instructions to 'requirements.txt' : 

```
blinker
rollbar
```

We then began implementing it in 'backend-flask.py' : 

```python
# Rollbar --------
import os
import rollbar
import rollbar.contrib.flask
from flask import got_request_exception
```

```python
# Rollbar ------
rollbar_access_token = os.getenv('ROLLBAR_ACCESS_TOKEN')
@app.before_first_request
def init_rollbar():
    """init rollbar module"""
    rollbar.init(
        # access token
        rollbar_access_token,
        # environment name
        'production',
        # server root directory, makes tracebacks prettier
        root=os.path.dirname(os.path.realpath(__file__)),
        # flask already sets up logging
        allow_logging_basic_config=False)

    # send exceptions from `app` to rollbar, using flask's signal system.
    got_request_exception.connect(rollbar.contrib.flask.report_exception, app)

@app.route('/rollbar/test')
def rollbar_test():
    rollbar.report_message('Hello World!', 'warning')
    return "Hello World!"

```
We then added an environment variable for Rollbar to 'docker-compose.yml' : 

```yml
      ROLLBAR_ACCESS_TOKEN: "${ROLLBAR_ACCESS_TOKEN}"
```
Running 'pip install -r requirements.txt' to install our Python dependencies, Andrew then walked us through Rollbar and how it can log errors. We purposely flubbed some code, implementing a warning to return "'Hello World!", then checked Rollbar and it cpatured the warning. 

![RollbarError](https://user-images.githubusercontent.com/119984652/222852467-2aae5e1f-85e2-4490-97a2-88bd73922a22.png)

## Watched Ashish's Week 2 - Observability Security Considerations

I watched Ashish's video on security considerations this week focusing on Observability. For this, I kept very detailed notes: 

```
Week 2 Notes - Cloud Security – Observability – Centralized tracing for Security and Speed in AWS Cloud

Current state of logging 
On-Premises Logs
-	Infrastructure
-	Application(s)
-	Anti-virus
-	Firewall
-	Etc

Cloud Logs
-	Infrastructure*** (may be challenges based on the type of compute used)
-	Application(s)***(PaaS may add additional complexity, but there should still be logs)
-	Anti-Virus
-	Firewall
-	Etc

Why Logging is Poopy
-	Time consuming
-	Tons of data with no context for Why of the security events?
-	Needle in a haystack to find things
-	Monolith vs Services vs Microservices
-	Modern Applications are distributed 
-	Many more haystacks and many more needles
-	Increase Alert Fatigue for SOC Teams and Application Teams(SREs, DevOps, etc)

Why Observability!
-	Decreased Alert Fatigue for Security Operations Teams
-	Visibility of end2end of Logs, metrics and tracing
-	Troubleshoot and resolve things quickly without costing too much money
-	Understand application health 
-	Accelerate collaboration between teams
-	Reduce overall operational cost
-	Increase customer satisfaction

Observability – what can I do to prevent the issue from reoccurring? 

Monitoring – Is my system backed up? 

What is Observability in AWS? 

“open-source solutions, giving you the ability to understand what is happening across your technology stack at any time. AWS observability lets you collect, correlate, aggregate, and analyze telemetry in your netowkr, infrastructure, and aplications in the cloud, hybrid, or on-premises enviornments so you can gain insights into the behavior, performance, and health of your system. These insights help you detect, investigate, and remediate problems faster; and coupled with artificial intelligence and machine learning, proactively react, predict, and prevent problems.”

Observability – 3 pillars: 

1.	Metrics – enhance what logs are being produced
2.	Traces – being able to trace it back to the pinpoint problem causing the issue in the first place
3.	Logs – every application produces logs

AWS Observability Services

-	AWS Cloudwatch Logs
-	AWS Cloudwatch Metrics
-	AWS Xray Traces

Instrumentation – what helps you produce logs or metrics or traces

AWS Services for instrumentation: AWS Cloudwatch, AWS Xray, AWS Distro for OpenTelemetry

Use Cloudwatch coming from CloudTrail or coming from EC2 for specific scenarios that are meant for security

Not all instrumentation agents offer all 3 of logs, metrics, and traces

Security is mostly logs and metrics

Building Security Metrics, Logs for Tracing:
1.	Application
2.	Threat model for known attack vectors
3.	Industry known attack patterns/techniques
4.	Identify Instrumentation Agents – e.g. SIEM tools, AWS Security HUB, SOAR tools, etc
a.	Uplifts Security Observability Dashboards
b.	Launch New Security Observability Dashboards

1.	Which application? 
2.	Type of application (compute, moonlight, microservices)
3.	Threat modelling session
4.	Identity Attack Vectors
5.	Map Attack Vectors to TTP in Attack MITRE Framework
6.	Identify instrumentation agents to create tracing (Cloudwatch or FireLens agent, 3rd party agents, etc)
7.	AWS services like AWS Distro for OpenTelemetry (ADOT) for metrics and traces
8.	Dashboard for Practical Attack Vectors only for that application
9.	Repeat for next application

Central Observability Platform – Security
-	AWS Security Hub with Amazon EventBridge
-	Open Source Dashboards
-	SIEM (Security Incident and Event Management)
-	Event Driven Architecture with AWS Services

Event Drive Security
-	Event Driven Architecture using Serverless
-	Auto Remediation with Amazon EventBridge and AWS Security Hub
-	AWS Services for Threat Detection – Amazon GuardDuty, 3rd party, etc

```

## Watch Chirag Week 2 - Spending Considerations

I listened to Chriag, as he laid out spending considerations for Observability. With Honeycomb using the free tier, a user is allotted 20 million events per month. With Rollbar's free tier, you're given 5,000 error events monthly. AWS X-Ray gives us 100,000 traces per month, always for free. Rounding us out, AWS Cloudwatch provides a meager 10 custom metrics and alarms per month, but does provide 5GB of Log Data Ingestion and 5GB of Log Data Archive. 

## Additional video content and Stretch Homework

### How to setup GitHub Codespaces

Andrew was gracious enough to walk us through how to setup GitHub Codespaces for those of us that are running low or out of credits through GitPod. To do so, first we need to cycle out our key from the AWS console since we don't have the key notated, which we did. Next, we need to add a .devcontainer directory, then create a 'devcontainer.json' file: 

```json
{
	"name": "Cruddur Configuration",
	"workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
	// Features to add to the dev container. More info: https://containers.dev/features.
	"features": {
		"ghcr.io/devcontainers/features/aws-cli:1": {}
	},
	"customizations": {
		"vscode": {
			"extensions": [
				"ms-azuretools.vscode-docker",
				"ms-python.python"
			]
		}
	}
	// Use 'forwardPorts' to make a list of ports inside the container available locally.
	// "forwardPorts": [],

	// Configure tool-specific properties.
	// "customizations": {},

	// Uncomment to connect as an existing user other than the container default. More info: https://aka.ms/dev-containers-non-root.
	// "remoteUser": "devcontainer"
	
}

```

We then updated the file after toying with it to get it to function correctly: 

```json
		"vscode": {
			"extensions": [
				"ms-azuretools.vscode-docker",
				"ms-python.python"
			],
			"settings": {
				"workbench.colorTheme": "Default Dark+ Experimental",
				"terminal.integrated.fontSize": 14,
				"editor.fontSize": 14
			}
```

To install the AWS CLI, we had to add an environment variable: 

```json
	"features": {
		"ghcr.io/devcontainers/features/aws-cli:1": {}
	},
	"remoteEnv": {
		"AWS_CLI_AUTO_PROMPT": "on-partial"
	},
	"customizations": {
		"vscode": {
			"extensions": [
```

We also had to add environment variables for GitHub Codespaces, then comment out our GitPod env var's in 'docker-compose.yml' for both our frontend and backend :

```yml
services:
  backend-flask:
    environment:
      FRONTEND_URL: "https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      #FRONTEND_URL: "https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      #BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"    
      FRONTEND_URL: "https://${CODESPACE_NAME}-3000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
      BACKEND_URL: "https://${CODESPACE_NAME}-4567.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"

```

```yml
      #REACT_APP_BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      REACT_APP_BACKEND_URL: "https://${CODESPACE_NAME}-4567.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
```

To switch back and forth between environments, all we would need to do is update our GitPod env vars for our AWS key, then swap which lines are commented out to use the correct variables for authentication to the AWS console and GitPod/GitHub Codespaces. 

### X-Ray: Part Deux

Thanks in part to fellow AWS Cloud Bootcamp member Olga, who was able to figure X-Ray out further, we were able to add additional segments and subsegments to X-Ray. We started this by removing all commments from our X-Ray code. After this with additional research, Andrew was able to find another way to call X-Ray. We updated endpoints in 'backend-flask/app.py' : 

```python
@app.route("/api/activities/home", methods=['GET'])
@xray_recorder.capture('activities_home')
def data_home():
  data = HomeActivities.run()
  return data, 200

@app.route("/api/activities/@<string:handle>", methods=['GET'])
@xray_recorder.capture('activities_users')
def data_handle(handle):
  model = UserActivities.run(handle)
  if model['errors'] is not None:
```

```python
@app.route("/api/activities/<string:activity_uuid>", methods=['GET'])
@xray_recorder.capture('activities_show')
def data_show_activity(activity_uuid):
  data = ShowActivity.run(activity_uuid=activity_uuid)
  return data, 200
```

Then, we updated 'backend-flask/services/user_activities.py' : 

```python
from aws_xray_sdk.core import xray_recorder
class UserActivities:
  def run(user_handle):
    try:
      model = {
        'errors': None,
        'data': None
      }

      now = datetime.now(timezone.utc).astimezone()
      
      if user_handle == None or len(user_handle) < 1:
        model['errors'] = ['blank_user_handle']
      else:
        now = datetime.now()
        results = [{
          'uuid': '248959df-3079-4947-b847-9e0892d1bab4',
          'handle':  'Andrew Brown',
          'message': 'Cloud is fun!',
          'created_at': (now - timedelta(days=1)).isoformat(),
          'expires_at': (now + timedelta(days=31)).isoformat()
        }]
        model['data'] = results

      subsegment = xray_recorder.begin_subsegment('mock-data')
      # xray -------
      dict = {
        "now": now.isoformat(),
        "results-size": len(model['data'])   
      }    
      subsegment.put_metadata('key', dict, 'namespace')
      xray_recorder.end_subsegment()
    finally:
      # Close the segment
      xray_recorder.end_subsegment()

    return model
``` 

### Run custom queries in Honeycomb and save them later

For this stretch homework task, I happened upon Boards in Honeycomb. This allows us to create many custom queries, then store them for later. Due to the Honeycomb limitation for who can view my boards, I'm only able to share the link here if you would like to view: [Honeycomb Board](https://ui.honeycomb.io/join_team/aws-devops-boot-camp)

Here's a couple of screenshots: both in list view and graph view

![CustomQueriesHoneycombGraphView](https://user-images.githubusercontent.com/119984652/222855991-e96f2771-b9b9-47ff-93e5-1d360d5414ba.png)

![CustomQueriesHoneycombListView](https://user-images.githubusercontent.com/119984652/222855992-58542361-b2d6-442e-8818-569a8f52950d.png)





