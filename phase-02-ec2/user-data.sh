#!/bin/bash
# Phase 2: staging web server for Mo's Custom Creations
dnf update -y
dnf install -y httpd git
systemctl enable --now httpd

# Deploy the site from GitHub
git clone https://github.com/andrewmercerkaw-cyber/aws-portfolio.git /tmp/repo
cp /tmp/repo/site/index.html /var/www/html/

# Status page from instance metadata (IMDSv2)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
MD="http://169.254.169.254/latest/meta-data"
ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $MD/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $MD/placement/availability-zone)
TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $MD/instance-type)
echo "<h1>Staging OK</h1><p>Instance: $ID</p><p>AZ: $AZ</p><p>Type: $TYPE</p>" > /var/www/html/status.html