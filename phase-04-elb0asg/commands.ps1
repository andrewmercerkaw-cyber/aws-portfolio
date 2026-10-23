# Phase 4: Load balancing and Auto Scaling. Commands run during the build, in order.
# Run in PowerShell on my PC unless marked (on server). This is a record, not a script
# to run top to bottom. Most resources were created in the console; the CLI was used
# to create the target group and to verify every step.

# --- 4.1 Pre-flight ---
aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,State.Name]" --output table
aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerName" --output table
aws elbv2 describe-target-groups --query "TargetGroups[].TargetGroupName" --output table
aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[].AutoScalingGroupName" --output table
aws ec2 describe-launch-templates --query "LaunchTemplates[].LaunchTemplateName" --output table

# --- 4.2 Security groups (verify) ---
aws ec2 describe-security-groups --filters "Name=group-name,Values=mos-web-sg" --query "SecurityGroups[].IpPermissions" --output json
# Fix for F-13: load balancer group had no inbound rules
aws ec2 authorize-security-group-ingress --group-id <mos-alb-sg-id> --protocol tcp --port 80 --cidr 0.0.0.0/0

# --- 4.4 Launch template (verify) ---
aws ec2 describe-launch-template-versions --launch-template-name mos-web-lt --query "LaunchTemplateVersions[].[VersionNumber,LaunchTemplateData.IamInstanceProfile]" --output json

# --- 4.5 Target group ---
$vpc = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
aws elbv2 create-target-group --name mos-web-tg --protocol HTTP --port 80 --vpc-id $vpc --target-type instance `
  --health-check-protocol HTTP --health-check-path /index.html --health-check-interval-seconds 10 `
  --health-check-timeout-seconds 5 --healthy-threshold-count 2 --unhealthy-threshold-count 2 `
  --matcher HttpCode=200 --tags Key=Project,Value=phase-04

# --- 4.6 / 4.7 Load balancer and Auto Scaling group (verify) ---
aws elbv2 describe-load-balancers --names mos-web-alb --query "LoadBalancers[].[State.Code,DNSName,SecurityGroups[0]]" --output table
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names mos-web-asg --query "AutoScalingGroups[].Instances[].[InstanceId,AvailabilityZone,LifecycleState,HealthStatus]" --output table
aws elbv2 describe-target-health --target-group-arn (aws elbv2 describe-target-groups --names mos-web-tg --query "TargetGroups[0].TargetGroupArn" --output text) --query "TargetHealthDescriptions[].[Target.Id,TargetHealth.State]" --output table

# --- 4.8 Load balancing test ---
$alb = aws elbv2 describe-load-balancers --names mos-web-alb --query "LoadBalancers[].DNSName" --output text
1..10 | ForEach-Object { (Invoke-WebRequest -UseBasicParsing "http://$alb/status.html").Content -split "`n" | Select-String "AZ:" }

# --- 4.9 Self-healing ---
# (on server) sudo systemctl stop httpd
aws autoscaling describe-scaling-activities --auto-scaling-group-name mos-web-asg --max-items 4 --query "Activities[].[StartTime,Description,Cause]" --output table

# --- 4.10 Load test ---
# (on each server) sudo dnf install -y stress-ng
# (on each server) nohup stress-ng --cpu 2 --timeout 900s > /dev/null 2>&1 &
aws cloudwatch describe-alarms --alarm-name-prefix TargetTracking-mos-web-asg --query "MetricAlarms[].[AlarmName,StateValue]" --output table
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization `
  --dimensions Name=AutoScalingGroupName,Value=mos-web-asg `
  --start-time (Get-Date).ToUniversalTime().AddMinutes(-20).ToString("o") `
  --end-time (Get-Date).ToUniversalTime().ToString("o") `
  --period 300 --statistics Average --query "sort_by(Datapoints,&Timestamp)[].[Timestamp,Average]" --output table

# --- 4.11 Teardown (correct order: Auto Scaling group FIRST) ---
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name mos-web-asg --force-delete
# then: delete load balancer, then target group, then launch template
aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[].AutoScalingGroupName" --output table
aws ec2 describe-instances --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" --query "Reservations[].Instances[].InstanceId" --output table
aws ec2 describe-volumes --query "Volumes[].[VolumeId,State]" --output table
aws cloudwatch describe-alarms --alarm-name-prefix TargetTracking --query "MetricAlarms[].AlarmName" --output table