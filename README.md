# AWS Portfolio: Mo's Custom Creations Website

Hands-on AWS project building a real small-business website, one phase at a time,
while I study for the **AWS Certified Solutions Architect – Associate** exam.
Each phase applies a section of the course to the same project and is documented with
what I built, why, and the proof that it works.

## Phases

| Phase | Topic | What I built | Status |
|---|---|---|---|
| [01](phase-01-iam/) | IAM & CLI | Secured root with MFA, admin group, budget alerts, CLI profiles, least-privilege policy lab | Done |
| [02](phase-02-ec2/) | EC2 | Staging web server that deploys itself from this repo with user data, IAM role (no keys), security group | Done |
| 03 | EBS, AMI, ELB & Auto Scaling | Custom AMI, multiple servers behind a load balancer with self-healing | Next |

## Skills demonstrated
- **Security first:** MFA, least privilege, IAM roles instead of stored credentials, account auditing with Credential Report and Access Analyzer
- **Infrastructure as code mindset:** servers are rebuilt from scripts, not hand-configured
- **Cost control:** budget alerts, same-day teardown, every phase verified clean with the CLI
- **Documentation:** each phase has a README and results file with real command output

## Tools
AWS (IAM, EC2, CLI) · Amazon Linux 2023 · Bash · PowerShell · Git & GitHub

## About me
Master Sergeant in the U.S. Air Force Reserve and KC-135R aircraft mechanic, with prior
IT experience supporting the Army National Guard (imaging, networking, trouble tickets).
I'm building this portfolio to grow into a cloud and IT role.
