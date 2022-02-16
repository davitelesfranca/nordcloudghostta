# Nord Cloud Ghost Technical Assignment - NordCloudGhostTA

* [Quickstart](#quickstart)
* [Overview](#overview)
* [Environment](#environment)
* [Issues](#issues)

## Quickstart

        To run in our own environment:
        1. Fork the project;
        2. Go to _**provider.tf**_ file and comment or erase the lines 13 to 22:


                _#To allow Github Actions be able to runs it on Hashicorp cloud environment, 
                # we need to define a organization and a workspace's organization
                cloud {
                  organization = "davitelesfranca"

                  workspaces {
                    name = "nordcloudghostta"
                  }   
                } 
               }_

        3. Install the AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html


              #Linux Environment
              - curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              - unzip awscliv2.zip
              - sudo ./aws/install
              - aws --version

        4. Configure your AWS Credentials (Access Key ID and Secret Access Key):


              $ aws configure
              - AWS Access Key ID [None]: YOUR_ACCESS_KEY_ID_HERE
              - AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY_HERE
              - Default region name [None]: us-east-1
              - Default output format [None]: json

        5. Install the Terraform CLI: https://learn.hashicorp.com/tutorials/terraform/install-cli


              #Linux Environment
              - sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
              - curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
              - sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
              - sudo apt-get update && sudo apt-get install terraform
              - terraform -version

        6. Finally apply:


           #Linux Environment
           - terraform init
           - terraform validate
           - terraform plan
           - terraform apply
           
           _**Be careful with the instance type that are setting on variable.tf file (lines 99 and 121). This can exceed the free tier limit.**_
   
   
## Overview
This is a GitOps project for Nord Cloud Technical Assignment. Git is the unique source of truth, where the infrastructure and application are declarative in order to manage them's configuration, continuous integration, and continuous delivery.

In each Pull Request, we have a set of automatic terraform steps (_init, fmt, validate and plan_) to test and validate the consistense of the requested update. When this phase achieve the success, the merge to the main branch is allowed. When the merge is requested, the terraform _apply_ is activated. Git Hub Actions orchestrate all. You can check it on _Actions tab_ or under _.github/workflows/_ directory.

Important: the merge **_only_** will be allowed if the first terraform steps are ok. And, even if the merge is released, the new code only will be merged to _main branch_ if the terraform apply is succeeded. And, with this last step triumphed, the new version of the infrascrutrure and/or the application will automatic deployed to the desired enviroment: production, dev, lab, etc.

This open the space to add unit tests, integration tests, smoke tests, regression tests, infrascruture test and any other tests that fits in your software development cicle. In our case, is a set of terraform cicle for infrastructure and aplication configuration and validation of changes.

## Enviroment
The proposal environment focous on Infrastructure as a Code - IaC. So, intention is to have the less human interaction as possible. To allow the GitOps, in provider.tf, was define the environment where the terraform code will run to deploy the infrastructure on AWS. We are using _**Hashicorp Cloud Environment - HCE**_. Because of it, you need to do the second step on #quickstart section. With this functionality, you can, for example, configure a Azure environment to run the terraform cloud that will provision the infrastructure on AWS (cool, right?). 

So, in HCE, we defined three ENV Variables:

        *AWS_ACCESS_KEY_ID: for AWS credentials; 
        *AWS_SECRET_ACCESS_KEY: for AWS credentials;
        *TF_VAR_mysql_password: for RDS password.

The TF and scritps files are named based on the service or functionality that they are configured for. 

We have the following tree:

                .
                ├── alb.tf
                ├── asg.tf
                ├── cloudwatch.tf
                ├── elk.tf
                ├── iam.tf
                ├── output.tf
                ├── provider.tf
                ├── rds.tf
                ├── README.md
                ├── s3.tf
                ├── user_data
                │   ├── init_user_data.sh
                │   └── nordcloud_ghost_init.sh
                ├── variables.tf
                └── vpc.tf


- alb.tf: _**Application Load Balancer**_ to balance the traffic of ghost instance within stick session; ***
- asg.tf: **_Auto Scalling Group_** configuration and the EC2 Ghost configuration remains here; *** 
- cloudwatch.tf: An instance of _**Cloudwatch**_ to monitor the EC2 instances and to vector** send logs to;
- elk.tf: _**Elastic Stack**_. For the send the vector collected logs;
- iam.tf: _**IAM**_ rules to filter access between the AWS services and external access;
- output.tf: prints the desire outputs of the configured infrascructure;
- provider.tf: Has the definition of AWS as the provider and the HCE to run the terraform;
- rds.tf: _**Relational Database Service**_. We use it to instantiate a MySQL Server to ghost aplication; 
- s3.tf: Creating buckets to vector send and storage logs. Plus, we used it to storage scritps;    
- user_data/: Here we have the initialization scripts: installing ghost prerequisites, install ghost and configure it. Install and configure vector.
- variables.tf:Here we find all variables used arround the project; 
- vpc.tf: VPC definitions of public (ELB and Ghost instance) and private networks (RDS);


*** Ghost documentations say: _"Ghost doesn’t support load-balanced clustering or multi-server setups of any description, there should only be one Ghost instance per site."_ https://ghost.org/docs/faq/clustering-sharding-multi-server/

Even with this recomentation, this project was a ALB and ASG, to shows the power and control of IaC. The strategy is to configured Sticky Session on ALB (lines 54 to 57).
                
## Issues
- Changes ELB from HTTP to HTTPS only. To do it, is necessary a validate certificate;
- Update the terraform AWS ELK configuration to AWS OpenSearch. Recently, AWS changes the service. So, connection between vector and terraform needs a review;
- IAM rules are too general. So, needing to add more filters and parameters to determine only which each resource really need to access;
- Create a version of this system to works with K8S and helm charts:
        * Ghost blog offers a community docker image. So, this can be tested and validated through helm charts. Vector already offers a helm deploys option.
- Evaluate the creation of a single file for security groups rules only. Since we had a few of them spread around of the others files, can be a good idea to manage all of them in a unique source.
- ENDPoint
- Backend file
- Multicloud & Multiregion
      
