## Architecture Guide

Before you run any templates, be sure to create an S3 Bucket to contain 
all of our artifacts for CloudFormation.

```
aws s3 mk s3://jh-cfn-artifacts
export CFN_BUCKET="jh-cfn-artifacts"
gp env CFN_BUCKET="jh-cfn-artifacts"
```

> remember bucket names are unique to the provided code example you may need to adjust