# Building a Small-Business Website on Amazon Web Services (AWS)

## What this is
This is a hands-on project where I'm building a real website for a small business,
Mo's Custom Creations, using Amazon Web Services, the cloud platform many companies run
their websites and apps on. I'm building it step by step while studying for the
**AWS Certified Solutions Architect – Associate** certification, so each phase puts
what I just learned into practice.

## The objective
To show I can do more than pass a test: set up a cloud environment securely, build
servers that run a real website, keep costs under control, and document my work
the way a professional team would.

## What each phase accomplishes

### Phase 1: Locking down the account ✅
**In plain English:** Before building anything, I secured the AWS account the way you'd
secure a building before moving in. I added two-step login, set up separate logins with
only the access each one needs, and turned on alerts that email me if spending starts.

*Technical: root MFA, IAM groups and users, least-privilege policy testing, AWS Budgets,
AWS CLI, Credential Report, IAM Access Analyzer* → [See Phase 1](phase-01-iam/)

### Phase 2: Building a web server that sets itself up ✅
**In plain English:** I created a server in the cloud that automatically installs
everything it needs and pulls the website from this GitHub page the moment it turns on,
with no manual setup. I gave it secure access without storing any passwords or keys
on it, and only opened the doors it needs (web traffic for everyone, admin access
only for me).

*Technical: Amazon EC2, user data scripts, IAM roles, security groups, instance
metadata, Elastic IPs* → [See Phase 2](phase-02-ec2/)

### Phase 3: Keeping the site up if a server fails (next)
**In plain English:** I'll make a reusable copy of the server and run several at once,
with a traffic director in front. If one server fails, another automatically takes its
place, and visitors never notice.

*Technical: EBS, custom AMIs, Elastic Load Balancing, Auto Scaling*

## How I work
- **Security first:** every phase follows least access and no stored passwords
- **Cost control:** I shut everything down the same day and verify nothing is left running
- **Proof, not claims:** each phase folder has a write-up and the real results
- **- **Full audit trail:** [step-by-step build record with rationale](docs/BUILD-PROCESS.md)

## About me
Master Sergeant in the U.S. Air Force Reserve and KC-135R aircraft mechanic, with prior
IT experience supporting the Army National Guard. I'm building this portfolio to grow
into a cloud and IT role.