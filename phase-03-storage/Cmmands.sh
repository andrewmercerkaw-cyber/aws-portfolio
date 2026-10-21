#!/bin/bash
# Phase 3: EC2 storage. Commands run during the build, in order.
# Lines marked [PC] ran in PowerShell on my PC; the rest ran on the servers.
# This is a record, not a script to run top to bottom.

# --- 3.0 Fresh start [PC] ---
# aws ec2 enable-ebs-encryption-by-default
# aws ec2 get-ebs-encryption-by-default

# --- 3.2 Data volume on mos-web-1 (us-east-1a) ---
lsblk                                   # find the new 1 GiB disk (nvme1n1)
sudo file -s /dev/nvme1n1               # "data" = blank, safe to format
sudo mkfs -t xfs /dev/nvme1n1           # ONLY on a new, empty volume

sudo cp -a /var/www/html /tmp/html-backup
sudo mount /dev/nvme1n1 /var/www/html
sudo cp -a /tmp/html-backup/. /var/www/html/
echo "<h1>Served from the mos-site-data EBS volume</h1>" | sudo tee /var/www/html/volume.html
df -h /var/www/html

# Persist the mount by UUID, then test before rebooting
UUID=$(sudo blkid -s UUID -o value /dev/nvme1n1)
echo "UUID=$UUID /var/www/html xfs defaults,nofail 0 2" | sudo tee -a /etc/fstab
sudo umount /var/www/html
sudo mount -a
df -h /var/www/html
sudo reboot
curl -I localhost/volume.html           # after reconnecting

# --- 3.3 Snapshot restore on mos-web-2 (us-east-1b) ---
echo "<h1>Added AFTER the snapshot</h1>" | sudo tee /var/www/html/after.html   # on web 1

# [PC] attach the restored volume
# aws ec2 attach-volume --volume-id <restored-volume-id> --instance-id <web-2-id> --device /dev/sdf

# On web 2 (launched without user data, so Apache installed by hand)
sudo dnf install -y httpd
sudo systemctl enable --now httpd
lsblk
sudo file -s /dev/nvme1n1               # "XFS filesystem data" = existing content, DO NOT format
sudo mount /dev/nvme1n1 /var/www/html
ls /var/www/html

# --- 3.5 EFS on both servers ---
sudo dnf install -y amazon-efs-utils
sudo mkdir -p /var/www/html/shared
sudo mount -t efs -o tls <file-system-id>:/ /var/www/html/shared
df -h /var/www/html/shared

echo "<h1>Shared on EFS: edited once, served everywhere</h1>" | sudo tee /var/www/html/shared/index.html   # web 1
echo "<h1>Edited from us-east-1b</h1>" | sudo tee /var/www/html/shared/index.html                       # AMI server

# --- 3.6 Teardown verification [PC] ---
# aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,State.Name]" --output table
# aws ec2 describe-volumes --query "Volumes[].[VolumeId,State]" --output table
# aws ec2 describe-snapshots --owner-ids self --query "Snapshots[].SnapshotId" --output table
# aws ec2 describe-images --owners self --query "Images[].ImageId" --output table
# aws efs describe-file-systems --query "FileSystems[].FileSystemId" --output table
# aws ec2 describe-addresses --output table