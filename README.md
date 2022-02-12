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
   
   
  ## Overview
  This is a GitOps project for Nord Cloud Technical Assignment. Git is the unique source of truth, where the infrastructure and application are declarative in order to manage them's configuration, continuous integration, and continuous delivery.
  
  In each Pull Request, we have a set of automatic terraform steps (_init, fmt, validate and plan_) to test and validate the consistense of the requested update. When this phase achieve the success, the merge to the main branch is allowed. When the merge is requested, the terraform _apply_ is activated. Git Hub Actions orchestrate all. You can check it on _Actions tab_ or under _.github/workflows/_ directory.
  
  Important, the merge **_only_** will be allowed if the first terraform steps are ok. And, even if the merge is released, the new code only will be merged if the terraform apply is succeeded. And, with this last step triumphed, the new version of the infrascrutrure and/or the application will automatic deployed to the desired enviroment: production, dev, lab, etc.
  
  This open the space to add unit tests, integration tests, smoke tests, regression tests, infrascruture test and any other tests that fits in your cicle. In our case, is a set of terraform cicle for infrastructure and aplication configuration and validation of changes.
         
      
