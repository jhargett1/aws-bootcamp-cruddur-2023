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

### Document the Notification Endpoint for the OpenAPI Document

