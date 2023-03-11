# Week 3 — Decentralized Authentication

### Setup Cognito User Pool
In this task, Andrew showed us how to create a Cognito User Pool through the AWS Console. To do this, we searched for Amazon Cognito, then selected "Create user pool." After a few initial mix-ups, we finally got the settings right (or so we thought at the time) and created our user pool.

![CruddurCognitoUserPool](https://user-images.githubusercontent.com/119984652/224451812-20566dda-8dec-406e-aa50-a277e17f8ac7.png)

With our user pool setup, we needed to pass the variables we set here into our docker-compose.yml file:

```yml
      REACT_APP_AWS_PROJECT_REGION: "${AWS_DEFAULT_REGION}"
      REACT_APP_AWS_COGNITO_REGION: "${AWS_DEFAULT_REGION}"
      REACT_APP_AWS_USER_POOLS_ID: "us-east-1_XXXXXXXXXX"
      REACT_APP_CLIENT_ID: "xxxxxxxxxxxxxxxxxxxxx"
```

To allow us to interact with our AWS Cognito User Pool, we also are implementing AWS Amplify through our code. To do this, we must add it to our 'App.js' file and store our environment variables as we did above. We hook our Cognito User Pool into our app, by adding code to 'App.js'

```js
import { Amplify } from 'aws-amplify';

Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_APP_AWS_PROJECT_REGION,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_APP_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
```

Then, we needed to implement a backend check for the JWT token in our 'HomeFeedPage.js' file by seeing if the user is logged in or not. 

```js
import { Auth } from 'aws-amplify';

```

![HomeFeedPagejs](https://user-images.githubusercontent.com/119984652/224452597-d688bc53-885a-475a-b39c-1825faff3a2f.png)

Our web app was previously setup to implement authentication by using Cookies to signify signed in and signed out states. We now also needed to edit our code in the 'ProfileInfo.js' file. 

```js
import { Auth } from 'aws-amplify';
```

I will use my commit history to show the edits below:

![ProfileInfojs](https://user-images.githubusercontent.com/119984652/224452868-c20a8ec2-54e6-422f-b474-0f634f5907cf.png)

I fell behind at the tail end of our livestream, so I paused the video and backtracked a bit to catch up and complete these changes. Once I was completed, I joined in on the after livestream discussion through our Bootcamp Discord channel. It was great to interact with fellow Bootcampers in a live setting and gain provided insight from Andrew as he answered our questions. 

### Implement Custom Signin Page

Near the end of the stream and into the next video, Andrew began working with us on altering our Sign-in page to use Auth from AWS Amplify and editing more code that was previously set.

![SignInPageAmplify](https://user-images.githubusercontent.com/119984652/224454072-7e75a618-88cf-46a0-be76-c56195021cce.png)

We found that the Sign-in page was still experiencing issues, so we print the value of 'user'

![ConsoleLogUser](https://user-images.githubusercontent.com/119984652/224454307-30485aae-729a-446f-90cf-d7a055651924.png)

### Implement Custom Signup Page

In the next video, we began more of the same, but with the Sign-Up page. We had to alter the existing code to utilize Auth from 'aws-amplify' and remove the "cookie" code.

```js
import { Auth } from 'aws-amplify';
.................................
  const onsubmit = async (event) => {
    event.preventDefault();
    setErrors('')
    console.log('username',username)
    console.log('email',email)
    console.log('name',name)
    try {
          const { user } = await Auth.signUp({
        username: email,
        password: password,
        attributes: {
          name: name,
          email: username,
          preferred_username: username,
        },
        autoSignIn: { // optional - enables auto sign in after user is confirmed
            enabled: true,
        }
      });
      console.log(user);
      window.location.href = `/confirm?email=${email}`
    } catch (error) {
        console.log(error);
        setErrors(error.message)
    }
    return false
  }

```

### Implement Custom Confirmation Page

We continued on, now doing the same to the Confirmation page.

![ConfirmationPage](https://user-images.githubusercontent.com/119984652/224454932-2ef7e40a-05a9-4206-9090-17e233e66132.png)

### Implement Custom Recovery Page

We then added Auth from 'aws-amplify' to 'RecoveryPage.js' and utilized Authentication.

```js
import { Auth } from 'aws-amplify';
............................
  const onsubmit_send_code = async (event) => {
    event.preventDefault();
    setErrors('')
    Auth.forgotPassword(username)
    .then((data) => setFormState('confirm_code') )
    .catch((err) => setErrors(err.message) );
    return false
  }
  const onsubmit_confirm_code = async (event) => {
    event.preventDefault();
    setErrors('')
    if (password == passwordAgain){
      Auth.forgotPasswordSubmit(username, code, password)
      .then((data) => setFormState('success'))
      .catch((err) => setErrors(err.message) );
    } else {
      setErrors('Passwords do not match')
    }
    return false
  }

```

We then had to edit the 'SignUpPage.js' file, as the attribute being passed for email needs to be set to email, as it's a required attribute of our Cognito User Pool. 

![EmailUsername](https://user-images.githubusercontent.com/119984652/224455376-6a6af56b-150c-4ea0-ab5f-68f8a40ca8aa.png)

### Watch about different approaches to verifying JWTs

For this video, it was more Andrew just exploring different options of how we could've implemented JWT tokens through our app. During the livestream , we ran into issues implementing authentication, as some of our variables needed edited, then we encountered a token expiring and issues clearing the token state when testing logging in and out. 

This video Andrew explained that we "look at different options and rule out why something works or why something doesn't work." We discussed several different options. What we did was write 'cognito_jwt_token.py' in its own library in the Backend that is called in app.py (embedding into app.py) Other things we could've done:

<ul>
  <li>Could write middleware, but would have to be written in same language as our server, which is Flask. To get this to work, we would need to run JWT middleware as a container horizontally next to our app (aka a sidecar). When we add additional containers, we would have to add compute, which would increase spend.</li>
  <li>Flask app with API gateway in front of it: endpoint in app tied to endpoint in API gateway(create a Lambda) - again, tradeoff could be cost. If app becomes popular with millions of users, API gateway is expensive. </li>
</ul>

### Watched Ashish's Week 3 - Decenteralized Authentication

I also watched Ashish's Security Best Practices for DeCentralized Authentication. For this, I kept detailed notes: 

```
AWS Boot Camp Week 3 Notes

DeCentralized Authentication in AWS Cloud

Common Types of App Authentication:
-	OAuth – used in conjunction with OpenID Connect
-	OpenID Connect -  open authentication protocol that works on top of the OAuth 2.0 framework. Use your Google account or social account to sign into app
-	Username/Password
-	SAML/Single Sign On and Identity Provider – security assertion markup language. A single point of entry into application. Face ID on phone is an example.
-	Traditional Physical Authentication – security badge for example

What is DeCentralized Authentication? 
-	No central authority to verify your identity
-	Allows users to use apps to not have to use username/password, a different way to authenticate

What is Amazon Cognito? 
-	Service which allows users to authenticate locally within application
-	AWS User directory 
-	2 types:
o	Cognito User Pool – used to authenticate for application
o	Cognito Identity Pool – used to administer access to AWS resources via AWS credentials tied to IAM role

Why use Cognito
-	User directory for customers
-	Ability to access AWS Resources for the Application being built
-	Identity Broker for AWS Resources with Temporary credentials
-	Can extend users to AWS Resources easily 

User Lifecycle Management

User provisioning process:
1.	Employee joins
2.	Create IT profile
3.	Assign birthright apps
4.	Onboard employee
5.	Additional apps requirements
6.	Changes
7.	Employee departs
8.	Offboard employee

-	New employee
-	Provision
-	Enforce
-	Update
-	Offboard
Token lifecycle management: 
-	User consented
-	App Developer sends access token
-	Refresh token
-	Consent revoked
-	Token revoked

1.	Token created
2.	Token Assigned
3.	Token Activated
4.	Token suspended
5.	Token removed
6.	Token expired

Amazon Cognito Security Best Practices

Amazon side: 
-	AWS services – API Gateway, AWS Resources shared with the app client (backend or back channels)
-	AWS WAF (web application firewall) with Web ACLs for Rate limiting, Allow/Deny List, Deny access from region and many more WAF management rules similar to OWASP (marketplace)
-	Amazon Cognito Compliance standard is what your business requires
-	Amazon Organizations SCP – to manage User Pool deletion, creation, region lock, etc
-	AWS CloudTrail is enabled and monitored to trigger alerts on malicious Cognito behavior by an identity in AWS

Client Application Side: 
-	Application should use an industry standard for Authentication and Authorization (SAML, OpenID Connect, OAuth2.0, etc)
-	App User Lifecycle Management – create, modify, delete users
-	AWS User Access Lifecycle Management – change of roles/ revoke roles, etc
-	Role based Access to manage how much access to AWS Resources for the Application being built
-	Token Lifecycle Management – issue new tokens, revoke compromised tokens, where to store (client/server) etc. 
-	Security tests of the application through penetration testing
-	Access Token Scope – should be limited
-	JWT Token best practice – no sensitive info
-	Encryption in Transit for API calls
```


### Making our app more user friendly to look at

Andrew gave us an additional video showing us how to edit the content of the styling for our web app, also known as the CSS. CSS is short for cascading style sheets, and is used as a way to format or style the elements in a webpage or web app. 

We learned how to update CSS by using variables to pass values. For example, in 'index.css', create: 

```css
:root{
   --variable: value()
   --variable: value()
}
```

Then on the CSS page, you can call the variable:

```css
.content{
width: 600px;
height: 100%;
background: var(--variable);
}
```

We used the Inspect element from our web browser after spinning up our environment to pinpoint elements within each page, then passed values by using variables for colors that match in our CSS stylings. This allowed us to provide a more uniform design across all pages. 

### Stretch Homework

That wrapped up all of the normal homework for Week 3 of the AWS Bootcamp. I then attempted to the stretch homework 'Implement a IdP login eg. Login with Amazon or Facebook or Apple.' 

To do this, I created a separate branch in my repo just to test whatever code implement changes I made. Most documentation I found kept referencing using AWS Amplify Authenticator, as it allows the use of federated social providers to add users to the user pool of Cognito. The only downside to this is it would render our custom sign-in page pointless. Authenticator invokes its own UI for sign-in's. 

Next I began looking for documentation for configuring social sign-in through OAuth using Amplify, and found this: https://docs.amplify.aws/lib/auth/social/q/platform/js/#configure-auth-category . 

I even followed along with several tutorials, but the documentation and tutorials both made use of the library by fully configuring Amplify through the AWS CLI or by setting up an app client in the Amplify console. I did a fair amount of research into this and found that I shouldn't incur any spend doing this, but I wasn't 100% sure how it would integrate within our already built app. 

Next I began looking at reconfiguring an existing authentication resource, as we already configured Amplify through 'app.js'. Apparently, you can use 'Auth.federatedSignIn()' to get AWS credentials directly from Cognito, but its from Federated Identities and not the User Pool federation. Additonally, the Amplify documentation said "In general, if you are using Cognito User Pools to manage user Sign-Up and Sign-In, you should only call Auth.federatedSignIn() when using OAuth flows or the Hosted UI." Since we aren't using the Hosted UI, I began looking into using OAuth flows. 

I found a bit of documentation and made several attempts to implement the code snippets found and implement them in different parts of our app. I finally reached a point Friday night (about 30 minutes ago) where I decided I needed to finish documenting my homework instead of working on this. I may not get this for the extra credit of stretch homework, but I feel like it's gave me a better understanding of what the code is doing, the token state, refreshing the token, and overall I feel like with a bit more time, I could eventually get this figured out. I'm going to come back to this after the bootcamp, so as to not keep me from completing new homework and do so. 
