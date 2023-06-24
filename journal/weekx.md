# Week X Cleanup!

With our AWS Cloud Project Bootcamp coming to a close, Week X was created to cleanup our application and get most of the features into a working state. 

Since a lot of this instruction was refactoring code and making minor adjustments, I have decided to implement ChatGPT to assist me with automating the task of summarizing my commit history. I'll break it down per section:

## Week X Sync tool for static website hosting

Created a new file called `bin/frontend/static-build` with the necessary build script.
 - This script builds the static files for the frontend application.

```sh
#! /usr/bin/bash 

ABS_PATH=$(readlink -f "$0")
FRONTEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $FRONTEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
FRONTEND_REACT_JS_PATH="$PROJECT_PATH/frontend-react-js"

cd $FRONTEND_REACT_JS_PATH

REACT_APP_BACKEND_URL="https://api.thejoshdev.com" \
REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
REACT_APP_AWS_USER_POOLS_ID="us-east-1_N7WWGl3KC" \
REACT_APP_CLIENT_ID="575n8ecqc551iscnosab6e0un3" \
npm run build
```

Modified `frontend-react-js/src/components/ActivityContent.css` to change the alignment of items to `flex-start`.
 - This change makes the items in the `ActivityContent` component appear in a single column instead of two columns.

```css
.activity_content_wrap {
  display: flex;
  flex-direction: row;
  align-items: flex-start;
}
```

Modified `frontend-react-js/src/components/DesktopNavigationLink.js` to add a default case to the switch statement.
 - This change ensures that the switch statement always returns a value, even if the provided value is not found.

```js
      case 'messages':
        return <MessagesIcon className='icon' />
        break;
      default:
        break;
    }
  }
```

Modified `frontend-react-js/src/components/DesktopSidebar.js` to update the footer links with correct URLs.
 - This change ensures that the footer links in the `DesktopSidebar` component point to the correct websites.

```js
      {suggested}
      {join}
      <footer>
        <a href="/about">About</a>
        <a href="/terms-of-service">Terms of Service</a>
        <a href="privacy-policy">Privacy Policy</a>
      </footer>
    </section>
  );
```

Modified `frontend-react-js/src/components/MessageForm.js` to remove an unused import statement.
 - This change removes an unused import statement from the `MessageForm` component.

```js
import './MessageForm.css';
import React from "react";
import process from 'process';
import { useParams } from 'react-router-dom';
import {getAccessToken} from '../lib/CheckAuth';

export default function ActivityForm(props) {
```

Modified `frontend-react-js/src/components/MessageGroupItem.css` to change the alignment of items to `flex-start`.
 - This change makes the items in the `MessageGroupItem` component appear in a single column instead of two columns.

```css
.message_group_item {
  display: flex;
  align-items: flex-start;
  overflow: hidden;
  padding: 16px;
  cursor: pointer;
```

Modified `frontend-react-js/src/components/MessageGroupItem.js` to update the comparison operator to strict equality (`===`).
 - This change ensures that the comparison operator in the `MessageGroupItem` component is always strict, which can help prevent errors.

```js
  const classes = () => {
    let classes = ["message_group_item"];
    if (params.message_group_uuid === props.message_group.uuid){
      classes.push('active')
    }
    return classes.join(' ');
```

Modified `frontend-react-js/src/components/MessageItem.css` to change the alignment of items to `flex-start`.
 - This change makes the items in the `MessageItem` component appear in a single column instead of two columns.

```css
.message_item {
  display: flex;
  align-items: flex-start;
  overflow: hidden;
  border-bottom: solid 1px rgb(31,36,49);
  padding: 16px;
```

Modified `frontend-react-js/src/components/ProfileForm.js` to comment out the creation of `preview_image_url` to avoid console error and comment out the `data` variable assignment.
 - This change prevents the creation of the `preview_image_url` variable in the `ProfileForm` component, which can avoid a console error.

```js
    const filename = file.name
    const size = file.size
    const type = file.type
    // const preview_image_url = URL.createObjectURL(file)
    console.log(filename,size,type)
    const fileparts = filename.split('.')
    const extension = fileparts[fileparts.length-1]
```

Modified `frontend-react-js/src/components/ProfileHeading.css` to change the alignment of items to `flex-start`.
 - This change makes the items in the `ProfileHeading` component appear in a single column instead of two columns.

```css
.profile_heading .info {
    display: flex;
    flex-direction: row;
    align-items: flex-start;
    padding: 16px;
}
```

Modified `frontend-react-js/src/components/ProfileInfo.js` to update the comparison operator to strict equality (`===`).
 - This change ensures that the comparison operator in the `ProfileInfo` component is always strict, which can help prevent errors.

```js
  const classes = () => {
    let classes = ["profile-info-wrapper"];
    if (popped === true){
      classes.push('popped');
    }
    return classes.join(' ');
```

Modified `frontend-react-js/src/components/ReplyForm.js` to remove an unused import statement.
 - This change removes an unused import statement from the `ReplyForm` component.

```js
import './ReplyForm.css';
import React from "react";
import process from 'process';

import ActivityContent  from '../components/ActivityContent';
```

Modified `frontend-react-js/src/pages/ConfirmationPage.js` to update the comparison operators to strict equality (`===`).
 - This change ensures that the comparison operators in the `ConfirmationPage` component are always strict, which can help prevent errors.

```js
      // does cognito always return english
      // for this to be an okay match?
      console.log(err)
      if (err.message === 'Username cannot be empty'){
        setErrors("You need to provide an email in order to send Resend Activiation Code")   
      } else if (err.message === "Username/client id combination not found."){
        setErrors("Email is invalid or cannot be found.")   
      }
    }
```

Modified `frontend-react-js/src/pages/RecoverPage.js` to update the comparison operators to strict equality (`===`) and remove an unused import statement.
 - This change ensures that the comparison operators in the `RecoverPage` component are always strict, which can help prevent errors.

```js
  const onsubmit_confirm_code = async (event) => {
    event.preventDefault();
    setErrors('')
    if (password === passwordAgain){
      Auth.forgotPasswordSubmit(username, code, password)
      .then((data) => setFormState('success'))
      .catch((err) => setErrors(err.message) );
```

```js
  let form;
  if (formState === 'send_code') {
    form = send_code()
  }
  else if (formState === 'confirm_code') {
    form = confirm_code()
  }
  else if (formState === 'success') {
    form = success()
  }
```

Modified `frontend-react-js/src/pages/SigninPage.js` to update the comparison operators to strict equality (`===`).
 - This change ensures that the comparison operators in the `SigninPage` component are always strict, which can help prevent errors.

```js
          window.location.href = "/"
        })
        .catch(error => { 
          if (error.code === 'UserNotConfirmedException') {
            window.location.href = "/confirm"
          }
          setErrors(error.message) 
```

Created a new file called `bin/frontend/sync` with a Ruby script for synchronizing files to AWS S3 and CloudFront.
 - This script synchronizes the files in the frontend application to AWS S3 and CloudFront.

```sh
#!/usr/bin/env ruby

require 'aws_s3_website_sync'
require 'dotenv'

file = "/workspace/aws-bootcamp-cruddur-2023/sync.env"
Dotenv.load()

  puts "sync =="
  AwsS3WebsiteSync::Runner.run(
    aws_access_key_id:     ENV["AWS_ACCESS_KEY_ID"],
    aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
    aws_default_region:    ENV["AWS_DEFAULT_REGION"],
    s3_bucket:             ENV["SYNC_S3_BUCKET"],
    distribution_id:       ENV["SYNC_CLOUDFRONT_DISTRUBTION_ID"],
    build_dir:             ENV["SYNC_BUILD_DIR"],
    output_changset_path:  ENV["SYNC_OUTPUT_CHANGESET_PATH"],
    auto_approve:          ENV["SYNC_AUTO_APPROVE"],
    silent: "ignore,no_change",
    ignore_files: [
      'stylesheets/index',
      'android-chrome-192x192.png',
      'android-chrome-256x256.png',
      'apple-touch-icon-precomposed.png',
      'apple-touch-icon.png',
      'site.webmanifest',
      'error.html',
      'favicon-16x16.png',
      'favicon-32x32.png',
      'favicon.ico',
      'robots.txt',
      'safari-pinned-tab.svg'
    ]
  )
```

Created a new file called `erb/sync.env.erb` with environment variable configurations for the synchronization script.
 - This file contains the environment variables that are used by the synchronization script.

```erb
SYNC_S3_BUCKET=thejoshdev.com
SYNC_CLOUDFRONT_DISTRUBTION_ID=E10S9HTQK39WH9
SYNC_BUILD_DIR=/workspace/aws-bootcamp-cruddur-2023/frontend-react-js/build
SYNC_OUTPUT_CHANGESET_PATH=
SYNC_AUTO_APPROVE=false
```

Updated the `bin/frontend/generate-env` script to add code to generate the `sync.env` file using the `erb/sync.env.erb` template.
 - This change ensures that the `sync.env` file uses the correct values for synchronization.

```sh
#!/usr/bin/env ruby
require 'erb'
template = File.read 'erb/frontend-react-js.env.erb'
content = ERB.new(template).result(binding)
filename = 'frontend-react-js.env'
File.write(filename, content)

template = File.read 'erb/sync.env.erb'
content = ERB.new(template).result(binding)
filename = 'sync.env'
File.write(filename, content)
```

Updated the `bin/frontend/sync` script to change the file mode to executable (100755).
 - This change ensures that the `sync` script can be executed without any errors.

Added additional code to the `bin/frontend/sync` script to display configuration information.
 - This change makes it easier to debug the synchronization script.

Modified the `output_changset_path` in the `bin/frontend/sync` script to include a timestamp.
 - This change makes it easier to track the changes made to the files during synchronization.

```sh
#!/usr/bin/env ruby
require 'aws_s3_website_sync'
require 'dotenv'

env_path = "/workspace/aws-bootcamp-cruddur-2023/sync.env"
Dotenv.load(env_path)

puts "== configuration"
puts "aws_default_region:   #{ENV["AWS_DEFAULT_REGION"]}"
puts "s3_bucket:            #{ENV["SYNC_S3_BUCKET"]}"
puts "distribution_id:      #{ENV["SYNC_CLOUDFRONT_DISTRUBTION_ID"]}"
puts "build_dir:            #{ENV["SYNC_BUILD_DIR"]}"

changeset_path = ENV["SYNC_OUTPUT_CHANGESET_PATH"]
changeset_path = changeset_path.sub(".json","-#{Time.now.to_i}.json")

puts "output_changset_path: #{changeset_path}"
puts "auto_approve:         #{ENV["SYNC_AUTO_APPROVE"]}"

puts "sync =="
AwsS3WebsiteSync::Runner.run(
  aws_access_key_id:     ENV["AWS_ACCESS_KEY_ID"],
  aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
  aws_default_region:    ENV["AWS_DEFAULT_REGION"],
  s3_bucket:             ENV["SYNC_S3_BUCKET"],
  distribution_id:       ENV["SYNC_CLOUDFRONT_DISTRUBTION_ID"],
  build_dir:             ENV["SYNC_BUILD_DIR"],
  output_changset_path:  changeset_path,
  auto_approve:          ENV["SYNC_AUTO_APPROVE"],
  silent: "ignore,no_change",
  ignore_files: [
    'stylesheets/index',
    'android-chrome-192x192.png',
    'android-chrome-256x256.png',
    'apple-touch-icon-precomposed.png',
    'apple-touch-icon.png',
    'site.webmanifest',
    'error.html',
    'favicon-16x16.png',
    'favicon-32x32.png',
    'favicon.ico',
    'robots.txt',
    'safari-pinned-tab.svg'
  ]
)
```

Synchronized the files using the updated configuration.
 - This ensures that the files in the frontend application are always synchronized with AWS S3 and CloudFront.

Updated the `erb/sync.env.erb` file to update the `SYNC_BUILD_DIR` and `SYNC_OUTPUT_CHANGESET_PATH` to use the `THEIA_WORKSPACE_ROOT` environment variable.
 - This change ensures that the `sync.env` file uses the correct values for the environment variables.

```erb
SYNC_S3_BUCKET=thejoshdev.com
SYNC_CLOUDFRONT_DISTRUBTION_ID=E10S9HTQK39WH9
SYNC_BUILD_DIR=<%= ENV['THEIA_WORKSPACE_ROOT'] %>/frontend-react-js/build
SYNC_OUTPUT_CHANGESET_PATH=<%= ENV['THEIA_WORKSPACE_ROOT'] %>/tmp
SYNC_AUTO_APPROVE=false
```

Updated `.gitpod.yml`:
 - Added a command to update the bundler package.
 - Installed `cfn-lint`, `cfn-guard`, and `cfn-toml` using `pip`, `cargo`, and `gem` respectively.

```yaml
  - name: cfn
    before: |
      bundle update --bundler
      pip install cfn-lint
      cargo install cfn-guard
      gem install cfn-toml
```

Updated `GemFile`:
 - Added a new file `GemFile` with Ruby gem dependencies.
 - The gems include `rake`, `aws_s3_website_sync` (tag: 1.0.1), and `dotenv`.

```gemfile
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rake'
gem 'aws_s3_website_sync', tag: '1.0.1'
gem 'dotenv', groups: [:development, :test]
```

Updated `RakeFile`:
 - Added a new file `RakeFile` with a sync task for synchronizing files.
 - The task utilizes the `AwsS3WebsiteSync` runner to sync files based on the provided configuration.

```rakefile
require 'aws_s3_website_sync'
require 'dotenv'

task :sync do
  puts "sync =="
  AwsS3WebsiteSync::Runner.run(
    aws_access_key_id:     ENV["AWS_ACCESS_KEY_ID"],
    aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
    aws_default_region:    ENV["AWS_DEFAULT_REGION"],
    s3_bucket:             ENV["S3_BUCKET"],
    distribution_id:       ENV["CLOUDFRONT_DISTRUBTION_ID"],
    build_dir:             ENV["BUILD_DIR"],
    output_changset_path:  ENV["OUTPUT_CHANGESET_PATH"],
    auto_approve:          ENV["AUTO_APPROVE"],
    silent: "ignore,no_change",
    ignore_files: [
      'stylesheets/index',
      'android-chrome-192x192.png',
      'android-chrome-256x256.png',
      'apple-touch-icon-precomposed.png',
      'apple-touch-icon.png',
      'site.webmanifest',
      'error.html',
      'favicon-16x16.png',
      'favicon-32x32.png',
      'favicon.ico',
      'robots.txt',
      'safari-pinned-tab.svg'
    ]
  )
end
```

Added `aws/cfn/sync/config.toml`:
 - Added a new file `aws/cfn/sync/config.toml` with deployment configuration.
 - Specifies the bucket, region, stack name, and other parameters.

```toml
[deploy]
bucket = 'jh-cfn-artifacts'
region = 'us-east-1'
stack_name = 'CrdSyncRole'

[parameters]
GitHubOrg = 'jhargett1'
RepositoryName = 'aws-bootcamp-cruddur-2023'
OIDCProviderArn = ''
```

Added `aws/cfn/sync/template.yaml`:
 - Added a new file `aws/cfn/sync/template.yaml` with CloudFormation template content.
 - Includes parameters, conditions, resources, and outputs for a CloudFormation stack.

```yaml
AWSTemplateFormatVersion: 2010-09-09
Parameters:
  GitHubOrg:
    Description: Name of GitHub organization/user (case sensitive)
    Type: String
  RepositoryName:
    Description: Name of GitHub repository (case sensitive)
    Type: String
    Default: 'aws-bootcamp-cruddur-2023'
  OIDCProviderArn:
    Description: Arn for the GitHub OIDC Provider.
    Default: ""
    Type: String
  OIDCAudience:
    Description: Audience supplied to configure-aws-credentials.
    Default: "sts.amazonaws.com"
    Type: String

Conditions:
  CreateOIDCProvider: !Equals 
    - !Ref OIDCProviderArn
    - ""

Resources:
  Role:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Statement:
          - Effect: Allow
            Action: sts:AssumeRoleWithWebIdentity
            Principal:
              Federated: !If 
                - CreateOIDCProvider
                - !Ref GithubOidc
                - !Ref OIDCProviderArn
            Condition:
              StringEquals:
                token.actions.githubusercontent.com:aud: !Ref OIDCAudience
              StringLike:
                token.actions.githubusercontent.com:sub: !Sub repo:${GitHubOrg}/${RepositoryName}:*

  GithubOidc:
    Type: AWS::IAM::OIDCProvider
    Condition: CreateOIDCProvider
    Properties:
      Url: https://token.actions.githubusercontent.com
      ClientIdList: 
        - sts.amazonaws.com
      ThumbprintList:
        - 6938fd4d98bab03faadb97b34396831e3780aea1

Outputs:
  Role:
    Value: !GetAtt Role.Arn 
```

Added `bin/cfn/sync`:
 - Added a new executable script `bin/cfn/sync` with deployment logic.
 - Performs linting, retrieves configuration from `config.toml`, and deploys the CloudFormation stack.

```sh
#! /usr/bin/env bash
set -e #stop the execution of the script if it fails

CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/sync/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/sync/config.toml"

cfn-lint $CFN_PATH 

BUCKET=$(cfn-toml key deploy.bucket -t $CONFIG_PATH)
REGION=$(cfn-toml key deploy.region -t $CONFIG_PATH)
STACK_NAME=$(cfn-toml key deploy.stack_name -t $CONFIG_PATH)
PARAMETERS=$(cfn-toml params v2 -t $CONFIG_PATH)

aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --s3-bucket $BUCKET \
    --s3-prefix sync \
    --region $REGION \
    --template-file $CFN_PATH \
    --no-execute-changeset \
    --tags group="cruddur-sync" \
    --parameter-overrides $PARAMETERS \
    --capabilities CAPABILITY_NAMED_IAM
```

Added `github/workflows/sync.yaml.example`:
 - Added a new file `github/workflows/sync.yaml.example` for a GitHub Actions workflow.
 - Includes steps for building and deploying static files, configuring AWS credentials, and running tests.

```yaml
name: Sync-Prod-Frontend

on:
  push:
    branches: [ prod ]
  pull_request:
    branches: [ prod ]

jobs:
  build:
    name: Statically Build Files
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [ 18.x]
    steps:
      - uses: actions/checkout@v3
      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}
      - run: cd frontend-react-js
      - run: npm ci
      - run: npm run build  
  deploy:
    name: Sync Static Build to S3 Bucket
    runs-on: ubuntu-latest
    # These permissions are needed to interact with GitHub's OIDC Token endpoint.
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Configure AWS credentials from Test account
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::554621479919:role/CrdSyncRole-Role-1K04C3W2EG8TG
          aws-region: us-east-1  
      - uses: actions/checkout@v3
      - name: Set up Ruby
        uses: ruby/setup-ruby@ec02537da5712d66d4d50a0f33b7eb52773b5ed1
        with:
          ruby-version: '3.1'
      - name: Install dependencies
        run: bundle install
      - name: Run tests
        run: bundle exec rake sync    
```

## Reconnect DB and Postgre Confirmation Lamba

Updated `aws/cfn/cicd/template.yaml`:
 - Modified the `ServiceName` parameter to explicitly specify the value as "backend-flask" instead of using a cross-stack reference.
 - The cross-stack reference to `${ServiceStack}ServiceName` has been commented out.

```yaml
                ClusterName: 
                  Fn::ImportValue:
                    !Sub ${ClusterStack}ClusterName
                # We decided not to use a cross-stack reference so we can
                # tear down a service independently    
                ServiceName: backend-flask
                  # Fn::ImportValue:
                   # !Sub ${ServiceStack}ServiceName
  CodePipelineRole:
    Type: AWS::IAM::Role
    Properties:
```

Updated `aws/cfn/service/template.yaml`:
 - Increased the `Timeout` value from 5 to 6 for the health check in the service definition.
 - Changes to Backend Flask.

```yaml
              - CMD-SHELL
              - python /backend-flask/bin/health-check
            Interval: 30
            Timeout: 6
            Retries: 3
            StartPeriod: 60
          PortMappings:
```

Updated `backend-flask/app.py`:
 - Wrapped the `init_rollbar` function inside `app.app_context()` to ensure it is executed within the application context.
 - The `init_rollbar` function initializes the Rollbar module and sets up exception reporting to Rollbar using Flask's signal system.
 - Changes to Docker Compose.

```py
# Rollbar ----------
rollbar_access_token = os.getenv('ROLLBAR_ACCESS_TOKEN')
with app.app_context():
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
```

Updated `docker-compose.yml`:
 - Modified the build configuration for the `backend-flask` service.
 - Changed the `build` field to include both the `context` and `dockerfile` properties.
 - The `context` is set to `./backend-flask` directory.
 - The `dockerfile` is set to `Dockerfile.prod`.

```yaml
  backend-flask:
    env_file:
      - backend-flask.env
    build: 
      context: ./backend-flask
      dockerfile: Dockerfile.prod
    ports:
      - "4567:4567"
    volumes:
```

Updated `aws/cfn/frontend/template.yaml`:
 - Added a new `CustomErrorResponses` section with an error response configuration.
 - Added a custom error response for HTTP error code 403.
 - The response code is set to 200, and the response page path is set to `/index.html`.

```yaml
          ViewerProtocolPolicy: redirect-to-https
        ViewerCertificate:
          AcmCertificateArn: !Ref CertificateArn
          SslSupportMethod: sni-only
        CustomErrorResponses: 
          - ErrorCode: 403
            ResponseCode: 200
            ResponsePagePath: /index.html
```
 
Updated `aws/lambdas/cruddur-post-confirrmation.py`:
 - Renamed the variable `user_cognito_id` to `cognito_user_id` for consistency.
 - Modified the SQL query to use named parameters instead of positional parameters.
 - Updated the `params` dictionary to use the named parameters.

```py
    user_display_name  = user['name']
    user_email         = user['email']
    user_handle        = user['preferred_username']
    cognito_user_id    = user['sub']
```

```py
         handle, 
          cognito_user_id
          ) 
        VALUES(
          %(display_name)s,
          %(email)s,
          %(handle)s,
          %(cognito_user_id)s
        )
      """
      print('SQL Statement ----')
      print(sql)
      conn = psycopg2.connect(os.getenv('CONNECTION_URL'))
      cur = conn.cursor()
      params = {
        'display_name': user_display_name,
        'email': user_email,
        'handle': user_handle,
        'cognito_user_id': cognito_user_id
      }
```

Updated `bin/db/schema-load`:
 - Added a new variable `DB_PATH` to store the path to the database directory.
 - Modified the assignment of `BIN_PATH` to use `DB_PATH` instead of `ABS_PATH`.
 - Added a new variable `PROJECT_PATH` to store the path to the project directory.
 - Updated the assignment of `BACKEND_FLASK_PATH` to use `PROJECT_PATH` instead of `BIN_PATH`.

```sh
#! /usr/bin/bash
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
DB_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $DB_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)


BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"
schema_path="$BACKEND_FLASK_PATH/db/schema.sql"
echo $schema_path
```

Updated `bin/db/seed`:
 - Added a new variable `DB_PATH` to store the path to the database directory.
 - Modified the assignment of `BIN_PATH` to use `DB_PATH` instead of `ABS_PATH`.
 - Added a new variable `PROJECT_PATH` to store the path to the project directory.
 - Updated the assignment of `BACKEND_FLASK_PATH` to use `PROJECT_PATH` instead of `BIN_PATH`.

```sh
#! /usr/bin/bash
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-seed"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
DB_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $DB_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"
seed_path="$BACKEND_FLASK_PATH/db/seed.sql"
echo $seed_path
if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi
psql $URL cruddur < $seed_path
```

## Fix CORS to use domain name for web-app

Updated `aws/cfn/service/config.toml`:
   - Added two new parameters under the `[parameters]` section:
     - `EnvFrontendUrl`: Set to `'https://thejoshdev.com'`.
     - `EnvBackendUrl`: Set to `'https://api.thejoshdev.com'`.

Updated `bin/cfn/service`:
   - Uncommented the `PARAMETERS` variable assignment, which retrieves the parameters from the `config.toml` file.
   - Added the `--parameter-overrides $PARAMETERS` option to the `aws cloudformation deploy` command, which passes the retrieved parameters to the CloudFormation deployment.
  
##  Ensure CI/CD pipeline works and create activity works

Updated `backend-flask/app.py`:
  - Added token verification using `cognito_jwt_token.verify()` to authenticate the request.
  - Replaced the `user_handle` variable with `cognito_user_id` in the `CreateActivity.run()` function call.
    
Updated `backend-flask/db/sql/activities/create.sql`:
  - Modified the query to use `cognito_user_id` instead of `user_handle` to match the new database schema.
    
Updated `backend-flask/services/create_activity.py`:
  - Replaced the `user_handle` parameter with `cognito_user_id` in the `CreateActivity.run()` and `CreateActivity.create_activity()` functions.

Updated `frontend-react-js/src/components/ActivityForm.js`:
  - Added the `getAccessToken()` function import from `../lib/CheckAuth`.
  - Retrieved the access token using `getAccessToken()` and added it to the `Authorization` header of the POST request.

Updated `docker-compose.yml`:
  - Modified the `dockerfile` entry for the `backend-flask` service to use `Dockerfile` instead of `Dockerfile.prod`.

Updated `config.toml` file in the `aws/cfn/cicd` directory:
  - Updated the `GithubRepo` parameter from `'aws-bootcamp-cruddur-2023'` to `'jhargett1/aws-bootcamp-cruddur-2023'`.

CloudFormation:
- Renamed the `CodeBuildBakeImageStack` stack to `CodeBuild`.
- Changed the `CodeBuildProjectName` output from the `CodeBuild` stack to reference the `CodeBuild` resource directly, instead of using the `GetAtt` intrinsic function.
- Updated the `Deploy` action in the `CodePipeline` pipeline to reference the `CodeBuild` project name directly, instead of using the `GetAtt` intrinsic function.
Updated `aws/cfn/cicd/config.toml`:
  - Added two new parameters under the `[parameters]` section:
    - `ArtifactBucketName`: Set to `'codepipeline-cruddur-artifacts-jh'`.
    - `BuildSpec`: Set to `'backend-flask/buildspec.yml'`.
Updated `aws/cfn/cicd/nested/codebuild.yaml`:
  - Added the `ArtifactBucketName` parameter to the `Parameters` section.
  - Added the `BuildSpec` parameter to the `Parameters` section.
Updated `aws/cfn/cicd/template.yaml`:
  - Added the `ArtifactBucketName` parameter to the `Parameters` section.
  - Added the `BuildSpec` parameter to the `Parameters` section.
  - Added a new policy to the `CodeBuild` stack. This policy allows the `CodeBuild` project to access the `ArtifactBucketName` S3 bucket.
  - Added a new policy to the `CodePipeline` stack. This policy allows the `CodePipeline` pipeline to access the `ArtifactBucketName` S3 bucket.
 
## Refactor to use JWT Decorator in Flask App

`backend-flask/app.py`:
- Added `from flask import request, g` in the import section.
- Replaced the `CognitoJwtToken` import with `jwt_required` from `lib.cognito_jwt_token`.
- Updated the `data_message_groups`, `data_messages`, `data_create_message`, `data_home`, `data_activities`, and `data_update_profile` functions to use the `jwt_required` decorator.
- Removed the `cognito_jwt_token` initialization.
- Added a new function `default_home_feed` to handle unauthenticated requests in `data_home`.

`backend-flask/lib/cognito_jwt_token.py`:
- Added the `jwt_required` decorator function, which wraps the decorated function with JWT token verification.
- Imported `wraps`, `partial`, `request`, `g`, and `os` in the import section.
- Updated the `jwt_required` function to store the user ID in the `g` object and handle unauthenticated requests.

`frontend-react-js/src/components/ReplyForm.js`:
- Added a new event handler `close` to handle closing the popup form.
- Added the `reply_popup` class to the wrapping div to apply styling for the reply popup.

## Refactor App.py

`backend-flask/app.py`:
- Imported and initialized various libraries and modules such as `init_rollbar`, `init_xray`, `init_cors`, and `init_cloudwatch`.
- Updated the routes to use the `model_json` function to handle the response data.
- Updated the `health_check` route to return the response data using the `model_json` function.
- Updated the `data_message_groups`, `data_messages`, `data_create_message`, `data_handle`, `data_search`, `data_activities`, `data_show_activity`, and `data_activities_reply` routes to return the response data using the `model_json` function.
- Updated the `data_users_short` and `data_update_profile` routes to return the response data using the `model_json` function.
- Added a new file `backend-flask/lib/cloudwatch.py` that defines the `init_cloudwatch` function for configuring the logger to use CloudWatch for logging.
- Added a new file `backend-flask/lib/cors.py` that defines the `init_cors` function for initializing CORS (Cross-Origin Resource Sharing) with Flask.
- Added a new file `backend-flask/lib/honeycomb.py` that defines the `init_honeycomb` function for initializing tracing and instrumentation with Flask using Honeycomb.
- Added a new file `backend-flask/lib/rollbar.py` that defines the `init_rollbar` function for initializing Rollbar error reporting with Flask.
- Added a new file `backend-flask/lib/xray.py` that defines the `init_xray` function for configuring AWS X-Ray for tracing with Flask.
- The import statement `from aws_xray_sdk.core import xray_recorder` has been added to `backend-flask/app.py`, suggesting the application is using the AWS X-Ray SDK for tracing and monitoring purposes.

`frontend-react-js/src/pages/NotificationsFeedPage.js`:
- Imported the `checkAuth` and `getAccessToken` functions from `lib/CheckAuth`.
- Updated the `loadData` function to call `getAccessToken` before making the API request and retrieve the access token from `localStorage`.
- Removed the import statement for the `Cookies` module.

## Refactor Flask Routes

`backend-flask/app.py`:
- The import statements have been updated to include the new routes and the `model_json` helper function from the `lib.helpers` module.
- The previous route handlers have been removed, and instead, the new route modules are imported and loaded using their respective load functions.
- The `init_rollbar` function has been removed from the `lib.rollbar` module, and the corresponding import statement has been removed from the `backend-flask/app.py` file.

`backend-flask/lib/helpers.py`:
- This is a new file that defines the `model_json` helper function, which extracts the data and errors from a model dictionary and returns them with the appropriate status code.

`backend-flask/lib/rollbar.py`:
- The `app` import statement has been removed, suggesting that the `init_rollbar` function may no longer depend on the Flask `current_app`.

`backend-flask/routes/general.py`:
- This is a new file that defines the route handlers for general endpoints, such as a health check endpoint.
- Currently, the health check route simply returns a JSON response indicating success.

`backend-flask/routes/activities.py`:
- This is a new file that defines the route handlers for activity-related endpoints, such as fetching home activities, creating activities, and searching activities.
- The existing route handlers for home activities, notifications, search activities, creating activities, and showing activities have been moved to this file.
- The `model_json` helper function is imported and used to return the appropriate JSON response.

`backend-flask/routes/messages.py`:
- This is a new file that defines the route handlers for message-related endpoints, such as fetching message groups, fetching messages within a group, and creating messages.
- The existing route handlers for message groups, messages, and creating messages have been moved to this file.
- The `model_json` helper function is imported and used to return the appropriate JSON response.

`backend-flask/routes/users.py`:
- This is a new file that defines the route handlers for user-related endpoints, such as fetching user activities, fetching user profiles, and updating user profiles.
- The existing route handlers for user activities and fetching user profiles have been moved to this file.
- The `model_json` helper function is imported and used to return the appropriate JSON response.

## Implement Replies for Posts

Backend Flask:
`backend-flask/db/migrations/16868683237445111_reply_to_activity_uuid_to_string.py`:
- Added a migration class `ReplyToActivityUuidToStringMigration` with methods for migrating and rolling back the column type of `reply_to_activity_uuid` in the activities table.
- The `migrate_sql()` method alters the column type to UUID, while the `rollback_sql()` method alters it back to integer.
- The `migrate()` method executes the migration SQL statement.
- The `rollback()` method executes the rollback SQL statement.

`backend-flask/db/sql/activities/home.sql`:
- Added a subquery in the SELECT statement to retrieve replies for each activity.
- The subquery selects relevant fields from the activities table and joins it with the users table to get user information.
- The subquery is aliased as `replies` and returned as a JSON array of objects named `replies` in the main query result.

`backend-flask/db/sql/activities/object.sql`:
- Added the `reply_to_activity_uuid` field in the SELECT statement to retrieve the reply's activity UUID.
- This change includes the `reply_to_activity_uuid` in the returned result for object activities.

`backend-flask/db/sql/activities/reply.sql`:
- This file contains an SQL statement for inserting a new reply into the activities table.
- The statement includes columns `user_uuid`, `message`, and `reply_to_activity_uuid`, which are populated with the provided values.

`backend-flask/routes/activities.py`:
- Updated the `data_activities_reply()` route to use the authenticated user's `cognito_user_id` instead of a hardcoded value.
- The `cognito_user_id` is obtained from the JWT token present in the request headers.
- This change ensures that the reply is associated with the correct user.

`backend-flask/services/create_reply.py`:
- Updated the `run()` method of the `CreateReply` class to use the `cognito_user_id` parameter instead of `user_handle`.
- The `create_reply()` method creates a new reply in the database, using the `cognito_user_id`, `activity_uuid`, and `message`.
- The `query_object_activity()` method queries the database for the newly created reply and returns the result as JSON.

Migrations:
- The `set_last_successful_run()` and `get_last_successful_run()` functions in the `bin/db/migrate` and `bin/db/rollback` scripts were modified to convert the last successful run time to/from an integer for consistency.
- The integer conversion ensures correct comparison with migration file timestamps.

Generation:
- The `bin/generate/migration` script now generates a migration file based on the provided class name (`{klass}Migration`).
- The migration file template is updated to include the correct class name and migration SQL statements.

Frontend React JS:
`frontend-react-js/src/components/ActivityActionReply.js`:
- Added a console log statement to log the clicked activity when the reply action is clicked.
- This change helps in debugging and tracking the activity that triggered the reply action.

`frontend-react-js/src/components/ActivityItem.css`:
- Added new styles for the replies section, including padding and background color.

`frontend-react-js/src/components/ActivityItem.js`:
- Wrapped the content and actions of each activity in a div element with the class `activity_main`.
- This change allows applying styles specifically to the activity's content and actions section.

`frontend-react-js/src/components/ReplyForm.js`:
- Updated the `handleSubmit()` method to include the `activity_uuid` when submitting the reply form.
- The `activity_uuid` is now sent along with the user's reply message when creating a new reply.

## Improved Error Handling for the app

Backend Flask:
`backend-flask/db/sql/activities/home.sql`:
- The subquery for retrieving replies has been removed.

`backend-flask/db/sql/activities/show.sql`:
- This file is now a copy of the `home.sql` file, except for the addition of a WHERE clause to filter activities by UUID.

`backend-flask/services/create_message.py`:
- The error message for exceeding the maximum character limit has been updated from `message_exceed_max_chars` to `message_exceed_max_chars_1024`.

`backend-flask/services/create_reply.py`:
- The error message for exceeding the maximum character limit has been updated from `message_exceed_max_chars` to `message_exceed_max_chars_1024`.

Frontend React JS:
`frontend-react-js/src/components/ActivityActionReply.js`:
- A console log statement has been removed.

`frontend-react-js/src/components/ActivityFeed.css`:
- A new CSS class called `.activity_feed_primer` has been added.

`frontend-react-js/src/components/ActivityFeed.js`:
- The rendering of the activity feed has been updated to display a primer message when there are no activities to show.

`frontend-react-js/src/components/ActivityForm.js`:
- The error handling for creating a new activity has been updated to use a post request helper function and handle errors.
- The error messages are now displayed using a new component called `FormErrors`.

`frontend-react-js/src/components/FormErrorItem.js`:
- A new component has been added to render individual error messages.

`frontend-react-js/src/components/FormErrors.css`:
- A new CSS file has been added to style the form errors.

`frontend-react-js/src/components/FormErrors.js`:
- A new component has been added to render a list of form errors.

`frontend-react-js/src/components/MessageForm.js`:
- The error handling for sending a new message has been updated to use a post request helper function and handle errors.
- The error messages are now displayed using the `FormErrors` component.

`frontend-react-js/src/lib/Requests.js`:
- Created a new file to contain helper functions for making HTTP requests.
- Implemented `request` function to handle common logic for making requests.
- Exported `post`, `put`, `get`, and `destroy` functions to handle different HTTP methods.

`frontend-react-js/src/pages/HomeFeedPage.js`:
- Added imports for `get` and `checkAuth`.
- Modified the `loadData` function to use the `get` function from the `lib/Requests` module.

`frontend-react-js/src/pages/MessageGroupNewPage.js`:
- Added imports for `get` and `checkAuth`.
- Modified the `loadUserShortData` and `loadMessageGroupsData` functions to use the `get` function from the `lib/Requests` module.

`frontend-react-js/src/pages/MessageGroupPage.js`:
- Added imports for `get` and `checkAuth`.
- Modified the `loadMessageGroupsData` function to use the `get` function from the `lib/Requests` module.

These changes indicate the usage of helper functions (`get`, `post`, `put`, `destroy`) from the `lib/Requests` module for making HTTP requests with different methods in the React.js project. The `FormErrors` component is also added to display form errors.

## Activities Show Page

Backend Flask:
`backend-flask/db/migrations/16868683237445111_reply_to_activity_uuid_to_string.py`:
- Changed the data type of the `reply_to_activity_uuid` column in the `activities` table from `uuid` to `integer`.

`backend-flask/db/sql/activities/home.sql`:
- Removed the trailing comma after `activities.created_at`.

`backend-flask/db/sql/activities/show.sql`:
- Restructured the SQL query to use a subquery and return the result as the `activity` field.

`backend-flask/routes/activities.py`:
- Removed the `data_show_activity` route.

`backend-flask/routes/users.py`:
- Added a new route `data_show_activity` to retrieve a specific activity for a user.

`backend-flask/services/show_activities.py`:
- Renamed to `backend-flask/services/show_activity.py`.

Frontend React JS:
`frontend-react-js/src/App.js`:
- Added a new route `ActivityShowPage` to display a specific activity.

`frontend-react-js/src/components/ActivityActionLike.js`:
- Added `event.preventDefault()` to prevent the default behavior of the click event.
- Added `return false` to prevent further event propagation.

`frontend-react-js/src/components/ActivityActionReply.js`:
- Added `event.preventDefault()` to prevent the default behavior of the click event.
- Added `return false` to prevent further event propagation.

`frontend-react-js/src/components/ActivityActionRepost.js`:
- Added `event.preventDefault()` to prevent the default behavior of the click event.
- Added `return false` to prevent further event propagation.

`frontend-react-js/src/components/ActivityActionShare.js`:
- Added `event.preventDefault()` to prevent the default behavior of the click event.
- Added `return false` to prevent further event propagation.

`frontend-react-js/src/components/ActivityContent.css`:
- Changed the CSS selector from `.activity_content a.activity_identity` to `.activity_content .activity_identity`.
- Modified the styles for `.activity_identity` and its child elements.

`frontend-react-js/src/components/ActivityContent.js`:
- Replaced the `<div>` element with a `<Link>` component for the `activity_avatar` element.
- Modified the structure and classes of the `activity_identity` element.

`frontend-react-js/src/components/ActivityForm.js`:
- Refactored the `post` function call to include an options object instead of individual parameters.
- Added an `auth` property with a value of `true` to the options object.
- Added a `success` property with a callback function to handle the successful response.

`frontend-react-js/src/components/ActivityItem.css`:
- Added styles for the `.activity_item` class and its `:hover` state.

`frontend-react-js/src/components/ActivityItem.js`:
- Imported the `Link` component from `react-router-dom`.
- Wrapped the entire `ActivityItem` component with a `Link` component to create a clickable link to the activity.
- Removed the `replies` variable, which was previously used to render replies within the component.

`frontend-react-js/src/components/MessageForm.js`:
- Refactored the `post` function call to include an options object instead of individual parameters.
- Added an `auth` property with a value of `true` to the options object.
- Added a `success` property with a callback function to handle the successful response.

`frontend-react-js/src/components/ProfileForm.js`:
- Refactored the `put` function call to include an options object instead of individual parameters.
- Added an `auth` property with a value of `true` to the options object.
- Added a `success` property with a callback function to handle the successful response.

`frontend-react-js/src/components/Replies.css` and `frontend-react-js/src/components/Replies.js`:
- These files define the styles and component for rendering replies to an activity.

`ReplyForm.js`:
- Added a new `options` parameter to the `post` function call in the `onsubmit` function.
- Updated the `post` function signature in `Requests.js` to accept the `options` parameter.
- Updated the `request` function in `Requests.js` to handle the `options` parameter and use it for error handling and authentication.

`ActivityShowPage.js`:
- Renamed the file from `HomeFeedPage.js` to `ActivityShowPage.js`.
- Updated the import statements to match the renamed file.
- Updated the `loadData` function to fetch a specific activity using the `handle` and `activity_uuid` parameters from the URL.
- Updated the JSX code to render the fetched activity and its replies using the `ActivityItem` and `Replies` components.

`HomeFeedPage.js`:
- Updated the `loadData` function to fetch activities with authentication.
- Removed the `setActivities` prop from the `ReplyForm` component.

`MessageGroupNewPage.js`:
- Updated the `loadUserShortData` and `loadMessageGroupsData` functions to fetch data with authentication.

`MessageGroupsPage.js`:
- Updated the `loadData` function to fetch message groups with authentication.

`NotificationsFeedPage.js`:
- Updated the `loadData` function to fetch notifications activities with authentication.

`UserFeedPage.js`:
- Updated the `loadData` function to fetch user activities without authentication.

## More General Cleanup Part 1 and Part 2

Backend Flask:
Modified `backend-flask/db/seed.sql` file:
- Added a new seed data entry for user "khargett".

Modified `backend-flask/services/show_activity.py` file:
- Changed `db.query_array_json` to `db.query_object_json`.

Modified `bin/db/migrate` file:
- Added a print statement to display the last successful run.

Frontend React JS:
Modified `frontend-react-js/src/pages/ActivityShowPage.js` file:
- Added the `expanded` prop to the `<ActivityItem>` component.
- Changed the title from "Home" to "Crud" in the `<div className='title'>`.

Modified `frontend-react-js/src/components/ActivityContent.js` file:
- Imported the `time_future` function from the `DateTimeFormats.js` module.
- Changed the `time_ago` function to `time_future` in the `ActivityContent` component.

Modified `frontend-react-js/src/components/ActivityItem.css` file:
- Changed the CSS class name from `.activity_item:hover` to `.activity_item.clickable:hover`.

Modified `frontend-react-js/src/components/ActivityItem.js` file:
- Imported the `useNavigate` hook from the `react-router-dom` module.
- Added a `click` function to handle the click event on the activity item.
- Added the `expanded_meta` variable for expanded activity item content.
- Modified the return statement to conditionally apply CSS classes and include the expanded meta content.

Modified `frontend-react-js/src/components/Replies.js` file:
- Removed a `console.log` statement.

Modified `frontend-react-js/src/lib/DateTimeFormats.js` file:
- Added a new function `time_future` to calculate the future time difference.
- Modified the `time_ago` function to calculate the past time difference.

Modified `frontend-react-js/src/lib/Requests.js` file:
- Removed a `console.log` statement.

New Files:
`frontend-react-js/src/components/ActivityShowItem.js`:
- Added a new file.
- Contains a React component for rendering an expanded activity item.
- Includes HTML structure, CSS class names, and JSX code for displaying activity details and actions.

`frontend-react-js/src/components/ProfileHeading.css`:
- Added `background-color: var(--fg);` to the `.profile_heading .banner` class.

Other Changes:
`frontend-react-js/src/components/ActivityContent.css`:
- Added `display: block;` to the `.activity_avatar` class.

`frontend-react-js/src/components/ActivityItem.css`:
- Added new CSS rules for the `.activity_item.expanded .activity_content` and `.activity_item.expanded .activity_content .activity_identity` classes.

`frontend-react-js/src/components/ActivityItem.js`:
- Simplified the logic related to `props.expanded`.
- Always adds the `expanded` class to the `activity_item` element.
- Assigned the `click` function to the `onClick` event.

`frontend-react-js/src/pages/ActivityShowPage.css`:
- Added new CSS rules for the `.back`, `.activity_feed_heading.flex`, and `.activity_feed_heading.flex .title` classes.

`frontend-react-js/src/pages/ActivityShowPage.js`:
- Replaced the `ActivityItem` component with the newly added `ActivityShowItem` component.
- Defined the `goBack` function to navigate back.
- Added a back button to the `activity_feed_heading` section.

`README.md`:
  - Updated the README.md file to mark all weeks as completed by changing the checkbox format from `- [ ]` to `- [x]`.

`frontend-react-js/src/components/MessageForm.js`:
  - Added an `errors` state variable to store any form submission errors.

`frontend-react-js/src/components/MessageGroupItem.js`:
  - Changed the format of the timestamp display to `<span className='ago'>{message_time_ago(props.message_group.created_at)}</span>`.

`frontend-react-js/src/components/ProfileForm.js`:
  - Added an `errors` state variable to store any form submission errors.

`frontend-react-js/src/lib/Requests.js`:
  - Updated to allow the `setErrors` option to be null, meaning the `setErrors` function will not be called if null.

`erb/sync.env.erb`:
  - Updated the `SYNC_OUTPUT_CHANGESET_PATH` variable to point to the new file `changeset.json`, used to store the changeset when the project is synced to S3.

`aws/cfn/service/config.toml`:
  - Added a new parameter called `DDBMessageTable` to specify the name of the DynamoDB table for storing messages.

`aws/cfn/service/template.yaml`:
  - Added a new resource called `DDBMessageTable` to create a DynamoDB table for storing messages.

`backend-flask/lib/ddb.py`:
  - Used the `DDBMessageTable` environment variable to specify the name of the DynamoDB table for storing messages.

`erb/backend-flask.env.erb`:
  - Added a new variable called `DDBMessageTable` to specify the name of the DynamoDB table for storing messages.

`frontend-react-js/src/components/MessageGroupItem.js`, `frontend-react-js/src/components/MessageGroupNewItem.js`, and `frontend-react-js/src/components/MessageItem.js`:
  - Utilized the `message_group_meta` and `message_meta` components to display the display name and handle of the user who created the message group or message.

`aws/cfn/machine-user/config.toml`:
  - Added new variables: `bucket` (specifies the S3 bucket for storing CloudFormation template), `region` (specifies the AWS region for deployment), and `stack_name` (specifies the name of the CloudFormation stack).

`aws/cfn/machine-user/template.yaml`:
  - Added a new resource `CruddurMachineUser` to create an IAM user with full access to DynamoDB.
  - Added a new resource `DynamoDBFullAccessPolicy` to attach a policy to `CruddurMachineUser` granting full access to DynamoDB.

`bin/cfn/machineuser`:
  - Created a script to deploy the `CrdMachineUser` stack.

`erb/backend-flask.env.erb`:
  - Commented out the `AWS_ENDPOINT_URL` variable since the `CrdMachineUser` stack will provide a production-grade DynamoDB endpoint.

`frontend-react-js/src/pages/MessageGroupPage.js`:
  - Updated the GET request to include `auth: true` to restrict API access to authenticated users.

## Other changes and updates

I also began working on other changes to the application, most notably the ability for posts or "Cruds" to delete when they expire. After some initial issues, posts are now deleting based on the `TTL` value provided by the user. 

I am still working on a way to get replies to Cruds to delete at the same time as the Crud does.

`backend-flask/db/sql/activities/delete.sql`:
  - Added a SQL query to delete old activities from the database. The query deletes activities with an `expires_at` value less than the current time minus the TTL.

`backend-flask/routes/activities.py`:
  - Updated the `data_home()` function to invoke the `delete_old_activities()` function from the `CreateActivity` class. This ensures regular deletion of old activities from the database.

`backend-flask/services/create_activity.py`:
  - Added a new function `delete_old_activities()` to delete expired activities from the database. The function accepts a TTL (time to live) value and calculates the expiration time using the `datetime` and `timedelta` modules.

`backend-flask/db/seed.sql`:
  - Added two new rows of seed data to the activities table.

`backend-flask/db/sql/activities/delete.sql`:
  - Modified the WHERE clause of the DELETE statement to compare the `expires_at` value with the current time.

`backend-flask/services/create_activity.py`:
  - Added a new function `delete_old_activities()` to delete activities that have expired, based on the provided TTL value.


I have also fixed the Profile page, so no matter what user is logged in, the page should display correctly:

`frontend-react-js/src/components/ProfileLink.js`:
  - Updated the `profileLink` property to use the `props.user.handle` prop instead of the hardcoded value `/@joshhargett`. This change ensures that the profile link always points to the user's profile, irrespective of their handle.

In the `ProfileLink` component, the `profileLink` property is used to render a link to the user's profile. The `url` prop of the `DesktopNavigationLink` component determines the `href` of the link. Previously, the `url` prop was hardcoded to the value `/@joshhargett`, resulting in the link always pointing to the profile of the user with the handle "joshhargett", even if a different user was logged in.

The updated code binds the `url` prop of the `DesktopNavigationLink` component to the `props.user.handle` prop. By doing so, the `url` prop is dynamically set to the handle of the current user. This change ensures that the profile link accurately reflects the profile of the logged-in user, regardless of their handle.
