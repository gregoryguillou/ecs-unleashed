# aws-unleashed

AWS unleashed regroups a set of deployment stacks to start a Terraform/AWS project quickly and efficiently. 

## How to start with new project

In order to start with a project, a few pre-steps are required:

- Starting with a new project assumes you've made a few consideration:
  - Name the ACCOUNT you want to use. This name can be anything and will only be used to configure (1) the name of configuration directory and (2) the name of the profile. If you've name your account with an alias, you mighyt want to choose the same name
  - Choose a ENV name for your configuration. That name should be less than 6 characters due to some restructions in the naming length on AWS. It could be staging or prod
  - Choose a REGION to deploy the configuration
- Install and configure AWS CLI
- Create a profile $REGION-$SHORTNAME in the .aws/credentials file and add the Access/Secret keys
- Install Terraform
- Install make

Terraform
Python and AWS CLI
A configuration to connect to the right account

```
ACCOUNT=resetlogs SHORTNAME=staging REGION=eu-west-1 make seed
```

## Storing Terraform states on S3

## Consul/ECS bootstrap


