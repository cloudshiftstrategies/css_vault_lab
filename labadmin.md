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
    
 2. collect lab public IP addresses from terrafrom output
    * TODO: create a script to format this output for lab organizer
    ```
    $ terraform output
 
    VAULT_PRIVATE_IP = [
        10.0.0.74
    ]
    WEB_PRIVATE_IP = [
        10.0.0.16
    ]
    WEB_PUBLIC_IP = [
        18.222.117.140
    ]
    WEB_PROFILE_ARN = arn:aws:iam::603006933259:instance-profile/vaultlab-dev-web-profile
    ```
