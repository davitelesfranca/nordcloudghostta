# Nord Cloud Ghost Technical Assignment - NordCloudGhostTA

* [Quickstart](#quickstart)
* [Overview](#overview)

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


      _#Linux Environment
      - curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      - unzip awscliv2.zip
      - sudo ./aws/install
      - aws --version_
      
4. Configure your AWS Credentials (Access Key ID and Secret Access Key):


      _$ aws configure
      AWS Access Key ID [None]: YOUR_ACCESS_KEY_ID_HERE
      AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY_HERE
      Default region name [None]: us-east-1
      Default output format [None]: json_
      
5. Install the Terraform CLI: https://learn.hashicorp.com/tutorials/terraform/install-cli


      _#Linux Environment
      sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
      curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
      sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
      sudo apt-get update && sudo apt-get install terraform
      terraform -version_

6. Finally apply:


   _terraform init
   terraform validate
   terraform plan
   terraform apply_
   
   
  ## Overview
  
   
         
      
