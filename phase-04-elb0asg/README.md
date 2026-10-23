# Phase 4: Load Balancing and Auto Scaling

## What I built
The Mo's Custom Creations site running behind an **Application Load Balancer**, served by an
**Auto Scaling group** of web servers spread across two Availability Zones:

- **Two chained security groups:** the load balancer accepts web traffic from anyone; the
  servers accept it only from the load balancer
- **A versioned launch template** holding every launch setting (AMI, instance type, security
  group, IAM role, IMDSv2, user data)
- **A target group with a fast health check** on `/index.html` (failure detected in ~20 seconds)
- **An Auto Scaling group** (min 2, max 4) using load balancer health checks
- **A target tracking policy** that keeps average CPU near 50%
- **A status page rebuilt on every boot,** so each server reports its own AZ (fixes a Phase 3 issue)

## Why it matters
- **No single point of failure.** Servers in two data centers; if one fails, the other keeps serving.
- **Self-healing.** A server whose website stops responding is replaced automatically.
- **Scales with demand.** More servers are added under load, within a cost cap.
- **Servers aren't directly exposed.** All traffic has to pass through the load balancer.
- **No launch mistakes.** The template makes every server identical, which prevents the
  wrong-security-group and missing-user-data problems from Phase 3.

## How I proved it
| Test | Result |
|---|---|
| Load balancing | 10 requests alternated evenly between us-east-1a and us-east-1b |
| Direct access blocked | A server's public IP timed out |
| Self-healing | Stopped Apache on one server: marked unhealthy in ~20 s, terminated and replaced 1 second later, healthy again ~3 min after. The site never went down. |
| Scale-out | Load on both servers pushed average CPU over 50%; the policy raised capacity from 2 to 3 |
| Teardown | Every resource deleted and verified empty with the CLI |

Full outputs are in [results.md](results.md), the server build script in
[user-data.sh](user-data.sh), and screenshots in [screenshots/](screenshots/).

## What went wrong and how I fixed it
| Problem | How I found it | Fix |
|---|---|---|
| SSH rule used the IPv6 Instance Connect list | CLI check of the security group | Replaced it with the IPv4 list |
| Editing a rule in place broke the HTTP rule | CLI check showed port 80 with no source | Deleted and recreated both rules |
| Load balancer's security group had no inbound rules | Console showed **Not reachable** on the listener | Added HTTP from anywhere |
| Launch template and target group didn't save at first | CLI `NotFound` errors | Re-created them; target group via the CLI |
| A check said the template had no IAM role | It read the role's name; the console saves the ARN | Checked the right field; nothing was wrong |
| Load test stuck at exactly 50% CPU | CloudWatch average | Load was only on one server; ran it on both |
| Auto Scaling group survived teardown | Verification showed 3 running servers | Force-deleted it; the group must be deleted first |

## What I'd do differently in production
- **HTTPS:** an ACM certificate on the load balancer with an HTTP-to-HTTPS redirect, once the
  site has a domain name
- **Patched golden AMI:** build one on a schedule (EC2 Image Builder) instead of installing
  software at every launch, for faster and more secure boots
- **Session Manager only:** remove the SSH rule entirely
- **Notifications:** send Auto Scaling launch and terminate events to SNS
- **Lower deregistration delay** (for example 30 s) for faster replacements on a site with short requests