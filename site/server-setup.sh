#!/bin/bash
# EC2 User Data - Amazon Linux 2023
# Installs Apache and lets ec2-user upload website files.
# The website itself is built in VS Code and uploaded with scp.
dnf update -y
dnf install -y httpd
systemctl enable --now httpd
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www/html
chmod 2775 /var/www/html
echo "<h1>Server is ready - upload your site.</h1>" > /var/www/html/index.html
