# css_vault_lab

## Lab organizer
1. deploy resources
    ```
    # clone the repo
    git clone git@github.com:cloudshiftstrategies/css_vault_lab.git
    
    # create an ssh-key for this project
    cd css_vault_lab/terraform/scripts
    ./create_sshkey.sh
    
    # set AWS_PROFILE so you can provision AWS resources
    export AWS_PROFILE=xxxx
    
    # Create an s3 bucket for your state-file
    ./create_s3bucket.py
    
    # edit the number of lab instances required in variables.tf - instCount
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
 
# Lab Instructions   
 
### Lesson 1. Unseal vault 
 1. Connect to the vault instance IP via browswer on port 8200
    * Point browser to http://x.x.x.x:8200 where x.x.x.x is the public IP of the vault server
    * Initialize vault with 3 keys and 2 required to unseal
    * Download keys to local PC
    * Unseal vault using 2 of 3 keys
    * Login to vault with root token
    
## Lesson 2. Generic Secrets
    
 1. Use the generic secrets backend to store information about the database
    * Open Vault Web CLI by clicking the ">_" button in top right of vault UI
    * Enter the following vault command:
      ```
      vault write secret/mysql host="127.0.0.1" port="3306" database="vaultlabdb"
      ```
    
    * check that we can read the secret stored
      ```
      vault read secret/mysql
      ```
    
## Lesson 3. Dynamic database secrets        

Note: A mysql database has already been initialized on the web server and a 
user:vaultadmin with password:vaultadminpassword has been created using the following SQL statement:
`GRANT ALL PRIVILEGES ON *.* TO 'vaultadmin'@'%' IDENTIFIED BY 'vaultadminpassword' WITH GRANT OPTION;`
     
 1. Enable database secrets backend
    * Secrets > Enable new engine > Database > Enable Engine
 
 2. Configure the connection to the mysql server and allow the role called "readwrite" to access it
    * Open Vault Web CLI by clicking the ">_" button in top right of vault UI
    * Enter the following vault command:
        ```
        vault write database/config/mysql \
            plugin_name=mysql-legacy-database-plugin \
            allowed_roles="readwrite"
            connection_url="vaultadmin:vaultadminpassword@tcp(x.x.x.x:3306)/"
        ```
        where **x.x.x.x** is the private IP address of the web server that hosts the MySQL database
        See `terraform output` WEB_PRIVATE_IP for this information
    
 3. Configure the role named "readwrite" that will create a user on the database with a 30 minute TTL
    * Enter the following vault command:
        ```
        vault write database/roles/readwrite \
            db_name=mysql \
            creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT ALL ON vaultlabdb.* TO '{{name}}'@'%';" \
            default_ttl="30m" \
            max_ttl="24h"
        ```
    
 4. Test that you can read dynamic database credentials
    * Enter the following vault command:
        ```
        vault read database/creds/readwrite
        ````    
    * example:
        ```
        > vault read database/creds/readwrite
        Key                Value
        ---                -----
        lease_id           database/creds/readwrite/cac5b044-1dd6-3838-0c22-4bcb98a1bab8
        lease_duration     30m
        lease_renewable    true
        password           A1a-3aGu4XTYkzZJoYG3
        username           v-read-nBR3gUX12
        ```

## Lesson 4. AWS EC2 authentication method

1. Create a policy for the web server
    * Open Vault Web CLI by clicking the ">_" button in top right of vault UI
    * Policies > Create ACL Policy
        * Name: web-policy
        * Policy: 
            ```
            path "sys/*" {
               policy = "deny"
            }
            path "secret/mysql*" {
               capabilities = ["read"]
            }
            path "mysql/creds/readwrite" {
               capabilities = ["read"]
            }
            ``` 
2. Enable EC2
    * Open Vault Web CLI by clicking the ">_" button in top right of vault UI
    * Enter the following vault command:
        ```
        vault auth enable aws
        vault write auth/aws-ec2/role/web-role \
            policies=web-policy \
            bound_iam_instance_profile_arn=arn:aws:iam::603006933259:instance-profile/vaultlab-dev-web-profile
        ```
        Where *bound_iam_instance_profile_arn* is the amazon resource name of the IAM instance
        profile that require be attached to the web instance to authenticate with vault.
        See `terraform output` WEB_PROFILE_ARN for this information.
        
## Lesson 5. ssh one time passwords

Note: A linux server has been already configured with the [vault-ssh-helper](https://github.com/hashicorp/vault-ssh-helper)
to allow remote users to access the server with one time passwords generated by our vault server. 

 1. Enable ssh secrets backend in vault UI
    * Secrets > Enable new engine > SSH > Enable Engine
    
 2. Create a role with the key_type parameter set to otp (one time password)
    * Open Vault Web CLI by clicking the ">_" button in top right of vault UI
    * Enter the following vault command:
        ```
        vault write ssh/roles/otp_key_role \
            key_type=otp \
            default_user=labuser \
            cidr_list=10.0.0.0/16
        ```
        Where **labuser** is the name of the linux user for which we will enable ssh access
        and **10.0.0.0/16** is the network(s) for which we will allows vault client connections for ssh
    
 3. Generate a One Time Password for the web host to which we want to connect
    * Open Vault Web CLI by clicking the ">_" button in top right of vault UI
    * Enter the following vault command:
        ```
        vault write ssh/creds/otp_key_role \
            ip=x.x.x.x
        ```
        where **x.x.x.x** is the private IP address of the web server that we want to access.
        See `terraform output` WEB_PRIVATE_IP for this information
        
        example:
        ```
        > vault write ssh/creds/otp_key_role ip=10.0.0.20
        Key      Value                               
        ip       10.0.0.20                           
        key      d534a560-bd49-6d7d-a929-81350b1bed23
        key_type otp                                 
        port     22                                  
        username labuser
        ```
    
 4. Ssh into the web server host using the one time password
    * Open a ssh client and enter the key from above as the one time password
        ```
        ssh labuser@y.y.y.y
        ```
        where y.y.y.y is the public IP of the web server.
        See `terraform output` WEB_PUBLIC_IP for this information
