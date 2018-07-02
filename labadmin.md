# css_vault_lab/labadmin.md

## Lab organizer

This lab is designed to very quickly demonstrate several of the features of [Hashicorp Vault](www.vaultproject.io)
including simple secrets engine (key/value pairs), dynamic database secrets, ssh one-time passwords and maybe
more in the future (i.e. Transit)

The /terraform directory of this repository includes terraform templates to deploy infrastructure in AWS. 
The templates are designed to allow each lab participant to have a dedicated vault instance and a dedicated 
web/database server hosted in AWS.  Just adjust the instCount variable in variables.tf to align with the
number of lab attendees you have. 


1. To deploy resources in AWS
    ```
    # clone the repo
    git clone git@github.com:cloudshiftstrategies/css_vault_lab.git
    
    # create an ssh-key for this project (should not need it except for troubleshooting)
    cd css_vault_lab/terraform/scripts
    ./create_sshkey.sh
    
    # set AWS_PROFILE so you can provision AWS resources (assumes ~/.aws/credentials has a profile lab)
    export AWS_PROFILE=xxxx
    
    # Create an s3 bucket for your state-file (creates a unique s3 bucket for state file)
    ./create_s3bucket.py
    
    # edit the number of lab instances required in variables.tf - instCount = number of lab attendees
    cd ../
    vi variables.tf
    
    # deploy your infrastructure!
    terraform init
    terraform apply -auto-approve
    ``` 
    
 2. collect and print lab public IP addresses from terrafrom output using the python ./fmtOutput.py script
 
    ```
    css_vault_lab/terraform $ ./lab_output.py 
    Lab User 1:
     Vault Public  IP: 18.188.127.201 (http://18.188.127.201:8200)
       Web Private IP: 10.0.0.13
       Web Public  IP: 18.216.38.230 (http://18.216.38.230:8000)
         Web ssh user: labuser `ssh labuser@18.216.38.230`
      Web Profile ARN: arn:aws:iam::603006933259:instance-profile/vaultlab-dev-web-profile

    Lab User 2:
     Vault Public  IP: 18.222.20.111 (http://18.222.20.111:8200)
       Web Private IP: 10.0.0.168
       Web Public  IP: 18.219.24.215 (http://18.219.24.215:8000)
         Web ssh user: labuser `ssh labuser@18.219.24.215`
      Web Profile ARN: arn:aws:iam::603006933259:instance-profile/vaultlab-dev-web-profile
 
    ```
    
  3. When the lab is complete, destroy the resources
  
    ```
    terraform destory
    ```
