# Week 1 — App Containerization

### Watch How to Ask for Technical Help
In this video, Andrew explained details of what to do if/when we run into any issues while working on our homework during the bootcamp. Screenshots, in depth researching, and various attempts at fixing should be made prior to reaching out for any assistance as it will at least indicate we're trying to fix it and not just waiting to be told what to do. 

### Watched Grading Homework Summaries
This video was quite eye-opening to me coming from the world of being a Systems Engineer/Admin. Things are to be documented but in shorter summaries that are easier to read. Considering there's 10,000 of us to grade, I can totally understand the logic behind this. Plus, it's a good insight for how to document work completed in a professional environment. 

### Watched Week 1 - Live Streamed Video
I missed the live stream this week due to a cross country move to Houston, TX from Missouri, but I got caught up later that evening, watching the live stream dealing with app containerization. Listening to James and Edith discuss containers and Docker in general, especially the syntax portion for me was quite helpful. I then re-watched the live stream to begin working on my project. 

### Remember to Commit Your Code
I was lucky to be late watching the livestream this week, as I followed along in this video with Andrew to commit the code I just worked on. 

### Watched Chirag's Week 1 - Spending Considerations 
I followed along with Chirag by checking my resources within AWS and Gitpod. Since it's the end of February, I should be good for the remainder of the month, but I will need to consider using Github codespaces if I continue to leave Gitpod open for too long. 

### Watched Ashish's Week 1 - Container Security Considerations
For Ashish's video this week, much like last week, I kept notes of what was covered. Here's my notes:

```
AWS Week 1 Notes
Container security – practice of protecting your applications hosted on compute services like Containers. Common examples of applications can be Single Page Applications (SPAs), Microservices, APIs, etc.

Why care about Container Security?
-	Container first strategy
-	Most applications are being developed with Containers and Cloud Native
-	Reducing impact of breach – segregation of application(s) and related services
-	Managed Container services means your security responsibility is focused on few things
-	Automation can reduce recovery times to a known good state fairly easy (kill old instance and spin up new)

Why Container Security requires practice? 
-	Complexity with Containers
-	Relying on CSPs for features
-	UnManaged requires a lot more hours of work then Managed but would require you keeping updated on everything containers
 
Container Security Components:
-	Docker and Host configuration
-	Securing Images
-	Secret Management
-	Application Security
-	Data Security
-	Monitoring Containers
-	Compliance Framework

Top 10 Security Best Practices
-	Keep host and Docker updated to latest security patches
-	Docker daemon and containers should run in non-root user mode
-	Image vulnerability scanning
-	Trusting a Private vs Public Image Registry
-	No Sensitive data in Docker files or Images
-	Use Secret Management Services to share secrets
-	Read only File system and Volume for Coker
-	Separate databases for long term storage
-	Use DevSecOops practices while building application security
-	Ensure all Code is tested for vulnerabilities before production use

Snyk – OpenSource Security for Docker Compose Vulnerability

Secret management: 
–	 AWS Secrets Manager – paid
–	Hashicorp Vault – OpenSource free

Image Vulnerability Scanning:
-	Amazon Inspector - 
-	Clair – OpenSource
-	Snyk - OpenSource
```

### Containerize Application (Dockerfiles, Docker Compose)
For this video, I finalized the containerization of the app following along with the rest of the live stream.

### Document the Notification Endpoint for the OpenAPI Document, Write a Flask Backend Endpoint for Notifications, and Write a React Page for Notifications
In this task, we created the openapi-3.0.yml file as a standard for defining APIs. The API is providing us with mock data, as there's currently no database hooked to the backend. 

We added a new section to the document:

```yml
  /api/activities/notifications:
    get:
      description: 'Return a feed of activity for all of those that I follow'
      tags:
        - activities
      parameters: []
      responses:
        '200':
          description: Returns an array of activities
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Activity'
```

To write a Flask Backend Endpoint for Notifications, we selected the app.py file and added the following to create a micro service:

```Python

from services.notifications_activities import * 

```
This was added added for the endpoint as well to define a route in the Flask app:

```Python
@app.route("/api/activities/notifications", methods=['GET'])
def data_notifications():
  data = NotificationsActivities.run()
  return data, 200
```
We then defined the micro service notifications_activites.py:

```Python
from datetime import datetime, timedelta, timezone
class NotificationsActivities:
  def run():
    now = datetime.now(timezone.utc).astimezone()
    results = [{
      'uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
      'handle':  'coco',
      'message': 'I am white unicorn',
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
    ]
    return results
```

For the Frontend, to implement the notifications tab, we went to the frontend-react-js folder. We accessed app.js, and added something new to import:

```Javascript
import NotificationsFeedPage from './pages/NotificationsFeedPage';
```

Using react-router, we added a new path for the element:

```Javascript
  {
    path: "/notifications",
    element: <NotificationsFeedPage />
  },
```

Then under pages, we created the pages NotificationsFeedPage.js and NotificationsFeedPage.css. We then opened the HomeFeedPage.js and copied and pasted the contents, editing it to reflect the different page:

```Javascript
import './NotificationsFeedPage.css';
import React from "react";

import DesktopNavigation  from '../components/DesktopNavigation';
import DesktopSidebar     from '../components/DesktopSidebar';
import ActivityFeed from '../components/ActivityFeed';
import ActivityForm from '../components/ActivityForm';
import ReplyForm from '../components/ReplyForm';

// [TODO] Authenication
import Cookies from 'js-cookie'

export default function NotificationsFeedPage() {
  const [activities, setActivities] = React.useState([]);
  const [popped, setPopped] = React.useState(false);
  const [poppedReply, setPoppedReply] = React.useState(false);
  const [replyActivity, setReplyActivity] = React.useState({});
  const [user, setUser] = React.useState(null);
  const dataFetchedRef = React.useRef(false);

  const loadData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/notifications`
      const res = await fetch(backend_url, {
        method: "GET"
      });
      let resJson = await res.json();
      if (res.status === 200) {
        setActivities(resJson)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  };

  const checkAuth = async () => {
    console.log('checkAuth')
    // [TODO] Authenication
    if (Cookies.get('user.logged_in')) {
      setUser({
        display_name: Cookies.get('user.name'),
        handle: Cookies.get('user.username')
      })
    }
  };

  React.useEffect(()=>{
    //prevents double call
    if (dataFetchedRef.current) return;
    dataFetchedRef.current = true;

    loadData();
    checkAuth();
  }, [])

  return (
    <article>
      <DesktopNavigation user={user} active={'notifications'} setPopped={setPopped} />
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
        <ActivityFeed 
          title="Notifications" 
          setReplyActivity={setReplyActivity} 
          setPopped={setPoppedReply} 
          activities={activities} 
        />
      </div>
      <DesktopSidebar user={user} />
    </article>
  );
}
```

We then committed the code. 

### Run DynamoDB Local Container and ensure it works and Run Postgres Container and ensure it works

For this video, I followed along with Andrew as we added DynamoDB local and Postgres as containers, by adding the following code to our Docker compose file: 

#### Postgres

```yml
services:
  db:
    image: postgres:13-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - '5432:5432'
    volumes: 
      - db:/var/lib/postgresql/data
```

#### DynamoDB Local

```yml
services:
  dynamodb-local:
    # https://stackoverflow.com/questions/67533058/persist-local-dynamodb-data-in-volumes-lack-permission-unable-to-open-databa
    # We needed to add user:root to get this working.
    user: root
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal
```

Then at the bottom of the docker-compose.yml file, we added the rest of the Postgress code for the volumes:

```yml
volumes:
  db:
    driver: local
```

Additionally, I also did several of the homework challenges. 


### Push and tag a image to DockerHub (they have a free tier)

I followed along with the tutorial provided by Docker Hub and pushed and tagged an image to DockerHub.

![DockerHubTutorial](https://user-images.githubusercontent.com/119984652/220816299-2d22198d-a5cd-4025-be91-209af33eba61.png)

Link: https://hub.docker.com/r/jhargett1/docker101tutorial

### Run the dockerfile CMD as an external script

I also tried to run the Dockerfile CMD as an external script. Here's what I did:

1. Created a script file called "myscript.sh" in the backend-flask directory. 

2. Added the following code to "myscript.sh":

```bash
#!/bin/bash
docker run -p 4567:4567 myimage python3 -m flask run --host=0.0.0.0 --port=4567
```
3. I made "myscript.sh" executable by adding the following:

```bash
chmod +x myscript.sh
```
4. From Terminal, I ran: 

```bash
docker build -t myimage .
```
At this point, I was getting an error on step 4. I was getting "unable to prepare context: unable to evaluate symlinks in Dockerfile path: lstat /workspace/DockerTutorialsandTesting/Dockerfile: no such file or directory." As it turned out, I needed to CD over to the correct directory. 

5. With this corrected, I then tried running the script:

```bash
./myscript.sh
```
At this point, it returned an error of "Unable to find image 'myimage:latest' locally
docker: Error response from daemon: pull access denied for myimage, repository does not exist or may require 'docker login': denied: requested access to the resource is denied." I realized that the image isn't actually called myimage:latest. I needed to rebuild. 

```bash
docker build -t aws-bootcamp-cruddur-2023-backend-flask:latest .
```

6. From there, I made it an executable:

```bash
chmod +x myscript.sh
```

7. I then tried running the script:

```bash
./myscript.sh
```
I received a lot of debugging messages, but I believe this worked, as when I tried accessing via the backend port, I got a 404 error. I can see from the code the request worked as well: 

```bash
'FLASK_ENV' is deprecated and will not be used in Flask 2.3. Use 'FLASK_DEBUG' instead.
'FLASK_ENV' is deprecated and will not be used in Flask 2.3. Use 'FLASK_DEBUG' instead.
'FLASK_ENV' is deprecated and will not be used in Flask 2.3. Use 'FLASK_DEBUG' instead.
 * Debug mode: on
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:4567
 * Running on http://172.17.0.2:4567
Press CTRL+C to quit
 * Restarting with stat
'FLASK_ENV' is deprecated and will not be used in Flask 2.3. Use 'FLASK_DEBUG' instead.
'FLASK_ENV' is deprecated and will not be used in Flask 2.3. Use 'FLASK_DEBUG' instead.
'FLASK_ENV' is deprecated and will not be used in Flask 2.3. Use 'FLASK_DEBUG' instead.
 * Debugger is active!
 * Debugger PIN: 626-519-123
192.168.41.202 - - [23/Feb/2023 02:33:36] "GET / HTTP/1.1" 404 -
192.168.41.202 - - [23/Feb/2023 02:33:36] "GET /favicon.ico HTTP/1.1" 404 -
```

After this, since I couldn't figure out a way to get this to work within the bootcamp, I removed the "myscript.sh" file and removed the comment tag from the CMD command in the Dockerfile. 

### Implement a healthcheck in the V3 Docker compose file

I was also able to find a basic healthcheck to run from the docker-compose.yml file:

```yml
    healthcheck:
      test: curl --fail http://localhost || exit 1
      interval: 60s
      retries: 5
      start_period: 20s
      timeout: 10s
```
### Additional work 
Found I was getting an exit code 127 when frontend-react-js runs and my site was inaccessible when running the docker-compose.yml file. After digging into the issue I was able to find a solution suggested by others in our Discord channel. Instead of this in the front-end-js Dockerfile:

```Docker
FROM node:16.18

ENV PORT=3000

COPY . /frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
EXPOSE ${PORT}
CMD ["npm", "start"]
```

I needed this:

```Docker
FROM node:16.18

WORKDIR /node
COPY package.json package-lock.json ./

RUN npm ci

WORKDIR /node/app
COPY . .

EXPOSE ${PORT}

ENV PORT=3000
CMD ["npm", "start"]
```

From what I understand, if the volume is mounted from the host, it overrides the installed node_modules. Additionally, I added 

```yml
    volumes:
      - ./frontend-react-js:/frontend-react-js
      - /frontend-react-js/node_modules # <- this line
```

To the "Volumes" section of the docker-compose.yml file. This tells Docker to create a second volume in addition to the one we already have. I was able to gather this information from a really helpful post by @Sergio on Discord. He added: 

Why do we do this?

- By adding the - /frontend-react-js/node_modules line, we are telling Docker to create a second volume (an anonymous volume) in addition to the one we already have, ./frontend-react-js:/frontend-react-js.
- When the containers are run, the Docker engine will use this secondary volume (/frontend-react-js/node-modules) to access the dependencies needed by the React application.
- This means that we no longer need to access the resources on our local computer. We only need the resources in the Docker container.
- As a result, we can remove the need for Node or any other local dependencies entirely.

### Cloud Careers - Roles for FREE AWS Cloud Project Bootcamp

I watched Lou's video regarding Cloud Careers and found it very insightful as it opened my mind to approaching this from a different perspective. For the homework Lou assigned, he asked we find 5 jobs online in our local market, fill out the "My Journey to the Cloud!" form, and then begin analyzing each job by asking ourselves questions. Are the skills I wrote down chohesive? Do the skills I wrote down align with my goal/the job I'm viewing? Are the skills I wrote down duplicate skills? Also, what category would this job actually fall under? Is it what it says it is or is it actually more of an analyst/manager role? 

![image](https://user-images.githubusercontent.com/119984652/221321889-3c599e01-945c-4916-9345-1b3c87b589b9.png)

#### My Journey to the Cloud! 
I am going to become a: Cloud Engineer

I am a good fit because: previous IT experience

I will know:
<ol>
 <li>Azure/AWS</li>
 <li>Python</li>
 <li>Terraform</li>
 <li>Docker</li>
 <li>Git Actions</li>
</ol>

I will not get distracted by: 
 <ol>
  <li>Certification chasing</li>
  <li>C#, Javascript</li>
  <li>ARM templates</li>
  <li>Hyper-V</li>
  <li>Other CI/CD toolings</li>
 </ol>
 
 In analyzing what I answered the questions on the form with, I began asking myself the questions on the Skills Roadmap Golden Rules:
 <ul>
 <li>Are skills "cohesive"?</li>
 After viewing the Cloud Engineer technical skills from https://openupthecloud.github.io/system , all of the skills I listed are cohesive.
 <li>Aligns with your goal</li>
 These skills fall entirely in line with my goals of becoming a cloud engineer, especially since the skills match.
 <li>Is not a "duplicate" skill</li>
 Azure/AWS is questionaable, but since I'm familiar in both, I plan to continue learning in both. 
 </ul>
 
 I then reviewed the documentation Lou provided [here.](https://thedevcoach-landing-pages.s3.eu-central-1.amazonaws.com/cdn/Your_Perfect_Cloud_Role_4_Questions_To_Get_Clarity_On_Your_Cloud_Journey.pdf)
 
 Next, I went to LinkedIn and began searching job postings. I searched specifically for "cloud engineer" as I knew it would yield various results. Here's what I found: 

### Job Description 1

![CloudEngineerJob1](https://user-images.githubusercontent.com/119984652/221323543-45f77e23-5248-4b15-a7e0-6d36a9000009.png)
 
Let's break this down versus what I listed:
I will know:
<ol>
 <li>Azure/AWS - the listing specifically mentions Azure </li>
 <li>Python - no mention of any programming languages at all </li>
 <li>Terraform - no mention of Terraform or any other IaaC </li>
 <li>Docker - no mention at all of containerization services </li>
 <li>Git Actions - no knowledge of CI/CD pipelines at all </li>
</ol>

From the looks of this job description, this is more of a support based role, specifically utilizing Azure and the VMWare Cloud Provider Stack. This role does not match up well with my goals.

### Job Description 2

![CloudEngineerJob2](https://user-images.githubusercontent.com/119984652/221323986-4c062cc4-8e8f-4ddb-921a-e7d8e0918e8f.png)
 
Let's break this down versus what I listed:
I will know:
<ol>
 <li>Azure/AWS - experience with any of the big 3 cloud providers </li>
 <li>Python - experience with Python/C/C++/Java </li>
 <li>Terraform - no mention of Terraform or any other IaaC </li>
 <li>Docker - no mention at all of containerization services </li>
 <li>Git Actions - mention of experience with version control </li>
</ol>

This job description appears to line up a bit more with my goals. There's also mention of API development, along with data storage, analytics, and big data handling, so this would fall under my umbrella, albeit a bit heavy on the data analyst/data engineer side of things. If I wanted to work towards this role, I would need to adjust my focus a bit to topics a bit more data driven. 

### Job Description 3

![CloudEngineerJob3](https://user-images.githubusercontent.com/119984652/221324397-263061c3-8344-49a1-ac8c-07ca58df7a8b.png)

 
Let's break this down versus what I listed:
I will know:
<ol>
 <li>Azure/AWS - experience with Azure is specified </li>
 <li>Python - experience with .NET is specified </li>
 <li>Terraform - experience with Terraform is mentioned </li>
 <li>Docker - Kubernetes is mentioned </li>
 <li>Git Actions - experience with CI/CD solutions mentioned </li>
</ol>

So far, this is probably the closest to form in roles that would line up for me. The only slight variance is C# instead of Python, but experience with one OOL is just as useful as any other and would likely be taken into consideration. This is a solid match. 

### Job Description 4

![CloudEngineerJob4](https://user-images.githubusercontent.com/119984652/221324642-0f27cba6-372c-4cf1-a989-fcd0a07e815c.png)

 
Let's break this down versus what I listed:
I will know:
<ol>
 <li>Azure/AWS - experience with any of the big 3 cloud providers </li>
 <li>Python - Python, Go, or a similar language </li>
 <li>Terraform - experience with IaaC </li>
 <li>Docker - no containerization mentioned </li>
 <li>Git Actions - no version control experience </li>
</ol>

This one seems like it would be a pretty good fit with the skills I provided too. There's a mention of "storage and networking configuration options" knowledge, but I'm thinking this is more cloud storage options and not Docker or any other type of containerization. I would apply to this job. 

### Job Description 5

![CloudEngineerJob5](https://user-images.githubusercontent.com/119984652/221324864-daadf5ad-6892-40f9-8042-be61fef1dd9f.png)

 
Let's break this down versus what I listed:
I will know:
<ol>
 <li>Azure/AWS - experience with AWS is mentioned specifically </li>
 <li>Python - Python, TypeScript, or Java </li>
 <li>Terraform - Ansible is mentioned specifically, but Terraform is mentioned for scripting </li>
 <li>Docker - no containerization mentioned </li>
 <li>Git Actions - CI/CD tooling such as Azure DevOps </li>
</ol>

I think this one matches up fairly decent as well. Again, I feel since it's specifically mentioned a couple of times, I would need to shift goals a bit to include Ansible, but given my current goals, I think I would pass on this particular role. One day I will come back to Ansible. 




