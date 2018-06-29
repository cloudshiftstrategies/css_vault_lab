#!/bin/bash -v
# webuserdata.sh - script used to initialize web servers

# Update all packages
yum -y update

# Install software
yum -qqy install gcc python-pip mysql-devel python-devel git

# Add a user for the vault daemon
useradd -r -g daemon -d /usr/local/flask -m -s /sbin/nologin -c "Flask user" flask

# create the directory where we'll run the web application
mkdir -p /var/www/html

# cleanup in case this script has been run before
rm -rf /var/www/html/* /tmp/iac_lab

# checkout our code from github
cd /tmp
git clone http://github.com/cloudshiftstrategies/iac_lab
cd iac_lab

# Move the web application into the web directory
mv iacapp/* /var/www/html
cd ~/ && rm -rf /tmp/iac_lab
chmod 755 -R /var/www/html

# Install the python requirements for the web application
pip install -r /var/www/html/requirements.txt

# Remove the unnessesary (possibly insecure) libraries after the pip install done above
yum -qqy remove gcc python-pip mysql-devel python-devel git

# Set the vault IP
echo "VAULT_IP = ${VAULT_IP}" > /VAULT_IP.txt

# Start Flask server
#cd /var/www/html
#sudo -u flask python run.py &

# Create the startup script
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

# Start the vault daemon
systemctl daemon-reload
systemctl start flask
systemctl enable flask

# Check the vault server status
export VAULT_ADDR=http://127.0.0.1:8200
/usr/local/bin/vault status
