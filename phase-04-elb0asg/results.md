# Phase 4 Results

All commands were run in PowerShell on my PC unless marked **(on server)**. Account IDs
are replaced with `<account-id>`.

## Step 1: Starting state

No instances, load balancers, target groups, Auto Scaling groups, or launch templates
existed in us-east-1. Reusable pieces confirmed:

```text
PS> aws iam get-role --role-name mos-staging-ec2-role --query "Role.Arn"
"arn:aws:iam::<account-id>:role/mos-staging-ec2-role"

PS> aws ec2 get-ebs-encryption-by-default
{
    "EbsEncryptionByDefault": true
}
```

## Step 2: Security groups

Two chained groups: the load balancer is public, and the web servers only accept traffic
from the load balancer's security group.

**`mos-alb-sg`** (after fixing a missing rule, finding F-13):
```text
PS> aws ec2 describe-security-groups --group-ids sg-03328602838900911 --query "SecurityGroups[].IpPermissions[].[FromPort,IpRanges[].CidrIp]" --output json
[ [ 80, [ "0.0.0.0/0" ] ] ]
```

**`mos-web-sg`** (after rebuilding both rules, findings F-11 and F-12):
```text
PS> aws ec2 describe-security-groups --filters "Name=group-name,Values=mos-web-sg" --query "SecurityGroups[].IpPermissions" --output json
[
    {
        "IpProtocol": "tcp", "FromPort": 80, "ToPort": 80,
        "UserIdGroupPairs": [ { "GroupId": "sg-03328602838900911" } ],   <- mos-alb-sg only
        "IpRanges": [], "PrefixListIds": []
    },
    {
        "IpProtocol": "tcp", "FromPort": 22, "ToPort": 22,
        "UserIdGroupPairs": [], "IpRanges": [],
        "PrefixListIds": [ { "PrefixListId": "pl-0e4bcff02b13bef1e" } ]  <- EC2 Instance Connect (IPv4)
    }
]
```

## Step 4: Launch template

```text
PS> aws ec2 describe-launch-template-versions --launch-template-name mos-web-lt --query "LaunchTemplateVersions[].LaunchTemplateData.[InstanceType,SecurityGroupIds,IamInstanceProfile.Name,MetadataOptions.HttpTokens]" --output json
[ [ "t3.micro", [ "sg-09c4072ec12d9a27a" ], null, "required" ] ]

PS> aws ec2 describe-launch-template-versions --launch-template-name mos-web-lt --query "LaunchTemplateVersions[].LaunchTemplateData.UserData != null" --output text
True
```

The `null` role name was a false alarm (finding F-15). The console stores the role as an
ARN, which the check above didn't read. Checking the right field shows both versions had
the role:

```text
PS> aws ec2 describe-launch-template-versions --launch-template-name mos-web-lt --query "LaunchTemplateVersions[].[VersionNumber,LaunchTemplateData.IamInstanceProfile]" --output json
[
    [ 2, { "Arn": "arn:aws:iam::<account-id>:instance-profile/mos-staging-ec2-role" } ],
    [ 1, { "Arn": "arn:aws:iam::<account-id>:instance-profile/mos-staging-ec2-role" } ]
]
```

- t3.micro, IMDSv2 required, user data present, role attached
- Version 2 created and set as the default (practice with launch template versioning)

## Step 5: Target group

Created from the CLI after the console attempt didn't save (finding F-14):

```text
PS> aws elbv2 describe-target-groups --names mos-web-tg --query "TargetGroups[].[TargetGroupName,HealthCheckPath,HealthCheckIntervalSeconds,HealthyThresholdCount,UnhealthyThresholdCount]" --output table
+-------------+---------------+-----+----+----+
|  mos-web-tg |  /index.html  |  10 |  2 |  2 |
+-------------+---------------+-----+----+----+
```

A failing server is detected in about 20 seconds, and a new server is marked healthy in
about 20 seconds.

## Step 6: Application Load Balancer

- `mos-web-alb`, internet-facing, us-east-1a and us-east-1b, security group `mos-alb-sg` only
- Listener HTTP:80 forwards to `mos-web-tg`
- The console flagged the listener **Not reachable** before any traffic was sent. The cause
  was that `mos-alb-sg` had no inbound rules (finding F-13).

## Step 7: Auto Scaling group

`mos-web-asg`: launch template `mos-web-lt` (default version), subnets in us-east-1a and
us-east-1b, ELB health checks on, 120-second grace period, min 2 / desired 2 / max 4.

The servers took about 3 minutes from launch to healthy, while user data finished running:

```text
PS> aws elbv2 describe-target-health ... --query "TargetHealthDescriptions[].[Target.Id,TargetHealth.State]" --output table
|  i-0e5775374b89200ee |  unhealthy  |      <- ~2 min after launch, user data still running
|  i-0380ec922c2e4f1b3 |  unhealthy  |

|  i-0e5775374b89200ee |  healthy  |        <- ~3 min after launch
|  i-0380ec922c2e4f1b3 |  healthy  |
```

## Step 8: Load balancing across two AZs

Ten requests to the status page through the ALB's DNS name:

```text
PS> 1..10 | ForEach-Object { (Invoke-WebRequest -UseBasicParsing "http://<alb-dns-name>/status.html").Content -split "`n" | Select-String "AZ:" }

<p>AZ: us-east-1b</p>
<p>AZ: us-east-1a</p>
<p>AZ: us-east-1b</p>
<p>AZ: us-east-1a</p>
<p>AZ: us-east-1b</p>
<p>AZ: us-east-1a</p>
<p>AZ: us-east-1b</p>
<p>AZ: us-east-1a</p>
<p>AZ: us-east-1b</p>
<p>AZ: us-east-1a</p>
```

- Requests alternated evenly between the two AZs (round robin).
- **F-10 closed:** each server rebuilds `status.html` at every boot from a cloud-init
  `per-boot` script, so every server reports its own AZ.
- Opening a server's public IP directly timed out, which proves traffic can only reach the
  servers through the ALB.

## Step 9: Self-healing

I stopped Apache on `i-0380ec922c2e4f1b3` with `sudo systemctl stop httpd` **(on server)**.

**Target health over time:**
```text
|  i-0e5775374b89200ee |  healthy    |
|  i-0380ec922c2e4f1b3 |  unhealthy  |   <- ~20 s after Apache stopped; ALB stops sending traffic

|  i-0e5775374b89200ee |  healthy   |
|  i-0380ec922c2e4f1b3 |  draining  |    <- Auto Scaling terminating it (connection draining)

|  i-0e5775374b89200ee |  healthy   |
|  i-0658685276c84ba13 |  initial   |    <- replacement launched
|  i-0380ec922c2e4f1b3 |  draining  |

|  i-0e5775374b89200ee |  healthy   |
|  i-0658685276c84ba13 |  healthy   |    <- replacement healthy, ~3 min later
|  i-0380ec922c2e4f1b3 |  draining  |
```

**Auto Scaling's own record:**
```text
PS> aws autoscaling describe-scaling-activities --auto-scaling-group-name mos-web-asg --max-items 4 --query "Activities[].[StartTime,Description,Cause]" --output table

15:06:03  Launching a new EC2 instance: i-0658685276c84ba13
          At 2026-10-23T15:06:02Z an instance was launched in response to an unhealthy
          instance needing to be replaced.

15:06:02  Terminating EC2 instance: i-0380ec922c2e4f1b3 - Waiting For ELB Connection Draining.
          At 2026-10-23T15:06:02Z an instance was taken out of service in response to an
          ELB system health check failure.

14:50:58  Launching a new EC2 instance: i-0380ec922c2e4f1b3
14:50:58  Launching a new EC2 instance: i-0e5775374b89200ee
          A user request created an AutoScalingGroup changing the desired capacity from 0 to 2.
```

The site stayed up the whole time on `i-0e5775374b89200ee`, and nothing was done by hand.

## Step 10: Scale-out under load

Target tracking policy `mos-cpu-50`: average CPU utilization, target 50%, 120-second warmup.
Load came from `stress-ng --cpu 2 --timeout 900s` **(on server)**, started with `nohup`
so it kept running after the session closed.

**Group average CPU (5-minute datapoints):**
```text
PS> aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=AutoScalingGroupName,Value=mos-web-asg ... --period 300 --statistics Average

11:06 ET   0.39%
11:11 ET  25.16%    <- stress-ng started on one server
11:16 ET  50.14%    <- one server at 100%, one at 0% = 50% average, right at target, no scale-out
11:21 ET  50.15%
```

The flat 50% showed that only one server was under load (finding F-16). After stress-ng
was started on both servers, the average went above 50% and the high alarm fired:

```text
PS> aws autoscaling describe-scaling-activities --auto-scaling-group-name mos-web-asg --max-items 3 ...

15:24:42  Launching a new EC2 instance: i-0114f154ad9957de4
          At 2026-10-23T15:24:28Z a monitor alarm
          TargetTracking-mos-web-asg-AlarmHigh-92160a86-6bf3-415a-848b-39125b3579c3 in state
          ALARM triggered policy mos-cpu-50 changing the desired capacity from 2 to 3.
          At 2026-10-23T15:24:40Z an instance was started in response to a difference between
          desired and actual capacity, increasing the capacity from 2 to 3.
```

The third server launched in us-east-1b and passed all status checks. I chose not to wait
for scale-in and went straight to teardown.

## Summary of what was proven

| Test | Result |
|---|---|
| Load balancing across 2 AZs | Requests alternated evenly between us-east-1a and us-east-1b |
| Status page per boot (F-10) | Each server reported its own AZ |
| No direct access to servers | Direct public IP timed out |
| Self-healing | Unhealthy server replaced automatically: ELB health check failure → replacement launched 1 second later |
| Scale-out | AlarmHigh → policy `mos-cpu-50` → desired capacity 2 to 3 |

## Step 11: Teardown

The first verification showed the Auto Scaling group and its 3 servers still running after
the load balancer, target group, and launch template were deleted (finding F-17):

```text
PS> aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[].AutoScalingGroupName" --output table
|  mos-web-asg            |

PS> aws ec2 describe-instances --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" ...
|  i-0114f154ad9957de4  |
|  i-0e5775374b89200ee  |
|  i-0658685276c84ba13  |
```

Fixed with:
```text
PS> aws autoscaling delete-auto-scaling-group --auto-scaling-group-name mos-web-asg --force-delete
```

Final verification: no Auto Scaling groups, load balancers, target groups, launch
templates, running instances, volumes, or TargetTracking alarms remained.

```text
(paste your final empty verification output here)
```

Kept (free): `mos-alb-sg`, `mos-web-sg`, `mos-staging-ec2-role`, and EBS encryption by default.