# Phase 2: EC2 Staging Server

## What I built
A staging web server on Amazon Linux 2023 (t3.micro) that deploys itself from
this repo on first boot using an EC2 user data script. Includes an IAM role,
a security group, and a status page built from instance metadata (IMDSv2).

## Why it matters
- **IAM role instead of access keys:** the server gets temporary, auto-rotating credentials, with nothing stored on the box to leak
- **Security group:** web traffic open to all, SSH only from my IP
- **User data:** the server can be destroyed and rebuilt identically in minutes

## How I proved it
- Site and status page loaded in the browser
- On the instance, `get-caller-identity` returned an assumed-role ARN; S3 read worked; IAM was denied; no credentials file exists
- Stop/start changed the public IP but not the private IP; an Elastic IP stayed fixed
- Torn down the same day and verified with the CLI (see results.md)

## What I'd do differently in production
- Add HTTPS
- Run multiple instances behind a load balancer with Auto Scaling (Phase 3)
- Use Session Manager and close port 22 entirely