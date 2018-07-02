#!/usr/bin/env python

import json, subprocess

# Get the ouputs from terraform output
output = subprocess.Popen(["terraform", "output", "-json"],
                          stdout=subprocess.PIPE).communicate()[0]
jOutput = json.loads(output)
webPublicIps = jOutput["WEB_PUBLIC_IPS"]["value"]
webPvtIps = jOutput["WEB_PRIVATE_IPS"]["value"]
vautPublicIps = jOutput["VAULT_PUBLIC_IPS"]["value"]
webProfileArn = jOutput["WEB_PROFILE_ARN"]["value"]

for i in range(len(webPublicIps)):
   print "Lab User %s:" %(i + 1)
   print "  Vault Public IP: %s (http://%s:8200)" %(vautPublicIps[i], vautPublicIps[i])
   print "   Web Private IP: %s" %webPvtIps[i]
   print "    Web Public IP: %s (http://%s:8000)" %(webPublicIps[i], webPublicIps[i])
   print "     Web ssh user: %s `ssh %s@%s`" %("labuser", "labuser", webPublicIps[i])
   print "  Web Profile ARN: %s" %webProfileArn
   print
