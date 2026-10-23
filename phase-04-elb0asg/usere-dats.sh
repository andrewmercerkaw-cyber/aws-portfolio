#!/bin/bash
# Phase 4: web server for Auto Scaling, Mo's Custom Creations
dnf install -y httpd git
systemctl enable --now httpd

# Deploy the site from GitHub
git clone https://github.com/andrewmercerkaw-cyber/aws-portfolio.git /tmp/repo
cp /tmp/repo/site/index.html /var/www/html/

# Status page script: cloud-init runs anything in per-boot on EVERY boot
cat > /var/lib/cloud/scripts/per-boot/status.sh <<'EOF'
#!/bin/bash
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
get() { curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/$1"; }
cat > /var/www/html/status.html <<HTML
<h1>Mo's Custom Creations: staging</h1>
<p>Instance: $(get instance-id)</p>
<p>AZ: $(get placement/availability-zone)</p>
<p>Private IP: $(get local-ipv4)</p>
<p>Generated: $(date -u)</p>
HTML
EOF
chmod +x /var/lib/cloud/scripts/per-boot/status.sh

# Run it now for the first boot
/var/lib/cloud/scripts/per-boot/status.sh