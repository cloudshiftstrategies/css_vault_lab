#!/bin/bash -v
# webuserdata.sh - script used to initialize web servers

###########################################################################
# Setup flask web server

# Install software
yum -y update
yum -qqy install gcc python-pip mysql-devel python-devel git

# Add a user for the flask web server daemon
useradd -r -g daemon -d /usr/local/flask -m -s /sbin/nologin -c "Flask user" flask

# create the directory where we'll run the web application
mkdir -p /var/www/html

# cleanup in case this script has been run before
rm -rf /var/www/html/* /tmp/iac_lab

# checkout our code from github
cd /tmp
git clone http://github.com/cloudshiftstrategies/css_vault_lab
cd css_vault_lab

# Move the web application into the web directory
mv webapp/* /var/www/html
cd ~/ && rm -rf /tmp/css_vault_lab
chmod 755 -R /var/www/html

# Install the python requirements for the web application
pip install -r /var/www/html/requirements.txt

# Remove the unnessesary (possibly insecure) libraries after the pip install done above
yum -qqy remove gcc python-pip mysql-devel python-devel git

# Create the flask system.d startup script
cat <<EOF | sudo tee /usr/lib/systemd/system/flask.service
[Unit]
Description=Flask Web service
After=network-online.target

[Service]
User=flask
Group=daemon
PrivateDevices=yes
PrivateTmp=yes
ProtectSystem=full
ProtectHome=read-only
SecureBits=keep-caps
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/python /var/www/html/run.py
KillSignal=SIGINT
TimeoutStopSec=30s
Restart=on-failure
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

# Start the vault daemon and enable to restart on boot
systemctl daemon-reload
systemctl start flask
systemctl enable flask

###################################################################
# Configure SSH Helper for Vault One Time Passwords

# Create a lab unix user account
useradd labuser -G sudoers
# Set simple password
#echo "password" |passwd labuser --stdin
# enable password logins over ssh (so that we dont have to give ssh keys to lab users)
#sed -i.bak s/"^PasswordAuthentication no"/"PasswordAuthentication yes"/ /etc/ssh/sshd_config
#service sshd restart

# Download the vault ssh auth method otp (one time password) helper
wget https://releases.hashicorp.com/vault-ssh-helper/0.1.4/vault-ssh-helper_0.1.4_linux_amd64.zip
unzip -j vault-ssh-helper_*_linux_amd64.zip -d /usr/local/bin

# Create a vault-ssh-helper config file
# **Note**, we are not using ssl or CA certs here.. in production, should use both
mkdir -p /etc/vault-ssh-helper.d
cat <<EOF | sudo tee /etc/vault-ssh-helper.d/config.hcl
vault_addr = "http://${VAULT_PRIVATE_IP}:8200"
ssh_mount_point = "ssh"
tls_skip_verify = false
allowed_roles = "*"
EOF

# modify the pam.d file to work with vault
cp /etc/pam.d/sshd /etc/pam.d/sshd.bak
# **Note**, we are using -dev mode because the non SSL mode is insecure
cat <<EOF | sudo tee /etc/pam.d/sshd
#%PAM-1.0
auth	   required	pam_sepermit.so
#auth      substack     password-auth # DISABLED FOR VAULT OTP PASSWORDS
auth       include      postlogin
auth       requisite    pam_exec.so quiet expose_authtok log=/tmp/vaultssh.log /usr/local/bin/vault-ssh-helper -config=/etc/vault-ssh-helper.d/config.hcl -dev
auth       optional     pam_unix.so not_set_pass use_first_pass nodelay
# Used with polkit to reauthorize users in remote sessions
-auth      optional     pam_reauthorize.so prepare
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    include      password-auth
session    include      postlogin
# Used with polkit to reauthorize users in remote sessions
-session   optional     pam_reauthorize.so prepare
EOF

# Modify the ssh config to work w/ vault one time passwords
sed -i.bak \
    s/"^ChallengeResponseAuthentication no"/"ChallengeResponseAuthentication yes"/ \
    s/"^UsePAM no"/"UsePAM yes"/ \
    s/"^PasswordAuthentication yes"/"PasswordAuthentication no"/ \
    /etc/ssh/sshd_config
service sshd restart

####################################################################################################################
# Configure a local mysql database for vault to manage dynamic passwords

# Install mysql database
yum install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb

mysqladmin -u root password R00tPassword

mysql -u root -p'R00tPassword' << EOF
GRANT ALL PRIVILEGES ON *.* TO 'vaultadmin'@'%' IDENTIFIED BY 'vaultadminpassword' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

