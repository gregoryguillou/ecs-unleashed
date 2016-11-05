# aws-unleashed

AWS unleashed regroups a set of deployment stacks to start a Terraform/AWS project quickly and efficiently. 

## Starting a new project

### Configure the environment

- If not already done, create an AWS account and a user in IAM that will be able to create and access the resources you plan to build. Get an Access/Secret Key for that user/account
- Install the required components, including: AWS CLI, Terraform, Git, Make and OpenSSL. If you run on Windows, create a Linux VM to use it.
- Fork this repository in your GitHub account by clicking the "Fork" button. Once done, clone it from a Linux/Mac machine with ```git clone https://github.com/[your account]/aws-unleashed.git```
- Choose and set the following environment variables:
  * ACCOUNT can be any name used to define your AWS account. You can use the name you've choosen to access your account or the account ID for instance
  * REGION is the AWS region you want to use. Note that most of the models included rely on 3 AZ and you would definitely prefer to use a region that as 3 AZs or more
  * ENV is a name from the environment you want to build and is used to differentiate between environments. Due to some AWS naming limits, ENV is limited to 6 characters in length.
- Register the Access/Secret Key with your AWS CLI; We rely on a convention that the profile is named <ACCOUNT>-<ENV> in the project
```
aws configure --profile=$ACCOUNT-$ENV
```

   Note:
   It is very important to set the environment variables as expected ; if you don't you might end up destroying some resources of another project. In order to avoid that, don't hesitate to set the variable as part of the command line and disabling the AWS CLI profile you don't want to use, including the default profile vy editing the ```~/.aws/credentials``` file.

### Initialize the project

The project assumes:

- Some variables are store in terraform/configurations/[ACCOUNT]/[SHORTNAME]
- State files are stored in a S3 bucket. 

As a result, you must initialize your environment first. The command below does that by creating a env.tfvars file with a uniquekey property in terraform/configurations/[ACCOUNT]/[SHORTNAME]. It also creates a S3 bucket named terraform-[SHORTNAME]-[UNIQUEKEY] to store the different state files:
```
ACCOUNT=resetlogs SHORTNAME=staging REGION=eu-west-1 make init
```


## Consul/ECS bootstrap


