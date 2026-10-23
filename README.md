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

### Phase 3: Giving the website its own storage ✅
**In plain English:** In Phase 2, the website lived on the server's own disk, so losing
the server meant losing the site. I moved the website onto a separate, encrypted disk that
survives the server being deleted, made a backup copy and restored it in a different
data center, saved a ready-to-go copy of the whole server so new ones start in seconds,
and set up shared storage so two servers in two data centers show the exact same files.

*Technical: EBS volumes, fstab mounts, EBS snapshots, cross-AZ restore, encryption by
default, golden AMIs, Amazon EFS, security-group-referenced NFS rules* → [See Phase 3](phase-03-storage/)

### Phase 4: Keeping the site up if a server fails ✅
**In plain English:** I put a "traffic director" (a load balancer) in front of the site and
ran copies of the server in two separate data centers. Visitors are spread across them
automatically. When I broke a server on purpose, it was detected in about 20 seconds and
replaced with a fresh one without me touching anything, and the site never went down. When
I pushed the servers hard, a third server was added automatically to handle the load.

*Technical: launch templates, Application Load Balancer, target groups and health checks,
Auto Scaling groups across two AZs, target tracking scaling, CloudWatch alarms,
security-group chaining* → [See Phase 4](phase-04-elb-asg/)

### Phase 5: Next
Following the course: databases, then a real domain name with HTTPS.

## How I work
- **Security first:** every phase follows least access and no stored passwords
- **Cost control:** I shut everything down the same day and verify nothing is left running
- **Proof, not claims:** each phase folder has a write-up and the real results
- **Full audit trail:** every step, the reason behind it, and the evidence are recorded in the [Build Process and Audit Record](#build-process-and-audit-record) below

## About me
Master Sergeant in the U.S. Air Force Reserve and KC-135R aircraft mechanic, with prior
IT experience supporting the Army National Guard. I'm building this portfolio to grow
into a cloud and IT role.

---

## Build Process and Audit Record

This document breaks the build into steps and sub-steps. For each one it records **what was done**, **why it was done**, and **where the evidence is**, so a reviewer can trace every decision and verify the result. Deviations, findings, and accepted risks are listed in their own sections instead of being hidden.

**Reference frameworks:** decisions map to the [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) pillars, noted in each table as **SEC** (Security), **COST** (Cost Optimization), **REL** (Reliability), and **OPS** (Operational Excellence).

**Where to look first:** the Findings Register and Accepted Risks show what went wrong, how I caught it, and what I'd change for production. Expand each phase below for the full step-by-step record.

### Findings Register

Issues discovered during the build and how each was resolved.

| ID | Finding | Severity | How found | Resolution | Status |
|---|---|---|---|---|---|
| F-01 | Daily admin user `Andrew` had no MFA | High | Credential report (Step 1.6.1) | MFA device assigned and confirmed at sign-in | Closed |
| F-02 | Unattached Elastic IP left in us-east-2, incurring hourly charges | Low | Pre-flight check (Step 2.0.2) | Released with `aws ec2 release-address` and verified | Closed |
| F-03 | CLI default region (us-east-2) did not match the working region (us-east-1), so checks missed resources | Medium | Pre-flight check (Step 2.0.3) | Default region changed to us-east-1. Checks now name the region explicitly when needed. | Closed |
| F-04 | `.gitignore` initially created as a folder instead of a file, so ignore rules were not active | Medium | `git status` review before first commit (Step 1.7.3) | Files moved to the repository root and re-verified before committing | Closed |
| F-05 | Direct `IAMReadOnlyAccess` policy on `Andrew` duplicates permissions already granted by the `admin` group | Low | Policy review (Step 1.3) | Detach with `aws iam detach-user-policy` so all permissions come from the group | Verify |
| F-06 | Console was set to us-east-2 (Ohio) while the build targets us-east-1, so the security group and key pair appeared to be missing | Medium | Launch wizard subnet list showed `us-east-2b` (Step 3.1.2) | Switched console region to N. Virginia before creating anything | Closed |
| F-07 | `mos-web-1` launched with an auto-created `launch-wizard-2` security group that allowed no HTTP, so the site timed out | Medium | Browser timeout, then `curl localhost` returned 200 and `describe-instances` showed the wrong group (Step 3.2.4) | Swapped to `mos-staging-sg`, added an EC2 Instance Connect prefix-list rule to it, and deleted `launch-wizard-2` | Closed |
| F-08 | `mos-web-2` launched without user data, so Apache was not installed and `/var/www/html` did not exist | Medium | Mount failed; cloud-init log finished in 11 s with no package installs (Step 3.3.5) | Installed Apache manually. Prevention: launch templates in Phase 4 | Closed |
| F-09 | Restored volume was created but never attached, so the OS could not see it | Low | `lsblk` showed only the root disk; `describe-volumes` showed no attachment (Step 3.3.4) | Attached with `aws ec2 attach-volume` and re-checked with `lsblk` | Closed |
| F-10 | `status.html` is generated once at build time, so copies made from a snapshot or AMI report the original server's AZ | Low | Browser check on the restored and AMI-launched servers (Steps 3.3.6, 3.4.3) Status page now rebuilt at every boot by a cloud-init per-boot script (Phase 4, Step 4.3) | Closed |
| F-11 | The Instance Connect SSH rule used the IPv6 prefix list, so console connections would fail | Low | CLI check showed `pl-09f9...` (`.ipv6`) (Step 4.2.3) | Replaced it with the IPv4 prefix list | Closed |
| F-12 | Editing a rule's source in place broke the web servers' HTTP rule, leaving port 80 with no source | Medium | CLI check of `mos-web-sg` (Step 4.2.3) | Deleted and recreated both rules, then verified the full rule set with the CLI | Closed |
| F-13 | `mos-alb-sg` had no inbound rules, so the load balancer would refuse all visitors | High | Console flagged the listener **Not reachable** (Step 4.6.2) | Added HTTP from 0.0.0.0/0 with `authorize-security-group-ingress` | Closed |
| F-14 | Launch template and target group didn't save on the first console attempt | Low | `NotFound` errors from CLI checks (Steps 4.4, 4.5) | Re-created the template; created the target group from the CLI | Closed |
| F-15 | A check reported the launch template had no IAM role, when it did | Low | The query read the role's name, but the console saves its ARN (Step 4.4.3) | No change needed. Lesson: verify the check before changing the resource | Closed |
| F-16 | Load test held the group at exactly 50% average CPU, so it never scaled out | Low | CloudWatch showed a flat ~50% (Step 4.10.3) | stress-ng was only on one server; ran it on both with `nohup` | Closed |
| F-17 | Teardown left the Auto Scaling group and 3 servers running after the load balancer was deleted | Medium | Teardown verification (Step 4.11.2) | Force-deleted the group. Correct order is Auto Scaling group first | Closed |

### Accepted Risks

Known gaps that are acceptable for a short-lived lab, with the planned production fix.

| ID | Risk | Why accepted | Production remediation |
|---|---|---|---|
| R-01 | SSH port 22 open to the owner's IP | Short-lived instance, single /32 source, key-based authentication only | Close port 22 and use Session Manager exclusively |
| R-02 | `AmazonS3ReadOnlyAccess` grants read access to every bucket, which is more than the workload needs | Used only to prove the role works, and no buckets exist | Replace with a custom policy scoped to specific buckets, or remove it |
| R-03 | The site is served over HTTP, not HTTPS | Staging only, no user data collected | Add a TLS certificate (AWS Certificate Manager) on a load balancer or CloudFront |
| R-04 | The admin user uses a long-lived CLI access key | Single user, key used from one machine | Move to IAM Identity Center with short-lived credentials, then deactivate the key. Deferred because enabling it creates an AWS Organization, which affects account plan and credit eligibility. |
| R-05 | Single instance, single Availability Zone | Staging only Load balancer plus Auto Scaling across two AZs, demonstrated in Phase 4 |
| R-06 | EFS automatic backups disabled | Lab data only, recreated from the repo | Enable AWS Backup for EFS, or keep automatic backups on |
| R-07 | Manual `mount` of EFS not added to fstab, so it would not survive a reboot | Short-lived lab | Add an `efs` entry with `_netdev,tls` to fstab, or mount from user data |
| R-08 | Servers skip `dnf update` at launch so they pass health checks faster | Short-lived lab servers | Patch a golden AMI on a schedule (EC2 Image Builder) and launch from it |
| R-09 | The load balancer serves HTTP only | No domain or certificate yet | Add an ACM certificate on an HTTPS listener and redirect HTTP to HTTPS (closes R-03) |

### Phase 1: Account Security Baseline

**Objective:** Secure the AWS account before any workloads exist, so every later phase is built on controlled access, monitored spending, and auditable identities.

**Design principles:**
1. The root user is never used for daily work.
2. Every human identity has MFA.
3. Permissions are granted through groups, not to individual users.
4. Every identity gets the least privilege it needs.
5. Spending is monitored from day one.

<details>
<summary><b>Show every step and sub-step with rationale</b></summary>

#### Step 1.1: Secure the root user

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.1.1 | Enabled MFA on the root user | Root has unrestricted access to the account, including billing and closing the account. A stolen root password without MFA is the worst-case compromise. | SEC | Credential report: `<root_account>` `mfa_active = true` |
| 1.1.2 | Confirmed no root access keys exist | Root access keys cannot be restricted by IAM policy. If leaked, they give programmatic full control of the account. AWS guidance is that root should never have keys. | SEC | Credential report: `access_key_1_active = false`, `access_key_2_active = false` |
| 1.1.3 | Stored root credentials in a password manager and stopped using root | Limits root use to the few tasks only root can perform, which reduces exposure. | SEC | Root `password_last_used` stops advancing after setup |

#### Step 1.2: Account-level settings

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.2.1 | Activated IAM user and role access to billing information | By default, even administrator IAM users cannot view billing or create budgets. Without this, cost monitoring would require signing in as root, which breaks principle 1. | SEC, COST | Admin IAM user can open Billing and Cost Management |
| 1.2.2 | Set an account password policy | Enforces password strength and prevents reuse for all IAM users with console access. | SEC | IAM → Account settings → Password policy |
| 1.2.3 | Created an account alias | Gives IAM users a readable sign-in URL. A convenience step, not a security control. | OPS | IAM dashboard shows alias |

#### Step 1.3: Administrative identity

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.3.1 | Created an `admin` group with the AWS-managed `AdministratorAccess` policy | Permissions attached to a group apply to every member. Adding or removing a person becomes a membership change instead of rebuilding permissions, which reduces error and makes access easy to review. | SEC, OPS | `aws iam list-attached-group-policies --group-name admin` |
| 1.3.2 | Used IAM user `Andrew` as the daily administrator, as a member of `admin` | Separates daily work from root. All actions are attributed to a named identity in logs. | SEC | `aws iam list-groups-for-user --user-name Andrew` returns `admin` |
| 1.3.3 | Enabled MFA on `Andrew` | The daily admin has full permissions through the group, so it needs the same protection as root. Initially missed, then found and fixed during the audit in Step 1.6 (finding F-01). | SEC | Credential report, after remediation |

#### Step 1.4: Cost controls

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.4.1 | Created an AWS Budget with email alerts | Detects unexpected spending, such as a forgotten instance or unattached IP address, within hours instead of at month end. Created before any compute was launched. | COST | Billing → Budgets |
| 1.4.2 | Reviewed the bill by service | Established a cost baseline and identified charges from earlier resources. This led to the decision to tear down rather than leave idle infrastructure running. | COST | Billing → Bills → Charges by service |

#### Step 1.5: Command-line access and least-privilege test

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.5.1 | Configured AWS CLI v2 with `Andrew`'s access key | Lets infrastructure be managed with repeatable, recordable commands instead of manual console clicks. | OPS | `aws sts get-caller-identity` returns `user/Andrew` |
| 1.5.2 | Set the CLI default region to us-east-1 | The default was us-east-2, while existing resources were in us-east-1. A mismatched default causes resources to be missed during checks (finding F-03). | OPS | `aws configure get region` returns `us-east-1` |
| 1.5.3 | Wrote a custom policy `S3ReadOnlyLab` allowing only `s3:ListAllMyBuckets`, `s3:ListBucket`, `s3:GetObject` | Demonstrates least privilege: an identity gets only the specific actions it needs. Written as a version-controlled JSON file so the policy is reviewable. | SEC | `phase-01-iam/s3-readonly-lab.json` |
| 1.5.4 | Created test user `test-readonly`, attached the policy, and configured a separate CLI profile | Isolates the test identity from the admin identity so results reflect only the custom policy. | SEC | `phase-01-iam/commands.ps1` |
| 1.5.5 | Ran one allowed and two disallowed actions as the test user | Proves the policy works by showing both what is allowed and what is denied. `iam:ListUsers` and `s3:CreateBucket` returned `AccessDenied` because no policy allowed them (implicit deny). | SEC | `phase-01-iam/results.md` |
| 1.5.6 | Deleted the test user's access key, detached the policy, deleted the user, and removed the local profile | Unused identities with active keys are a common source of breaches. Order matters: AWS will not delete a user with keys or policies still attached. Deletion was verified rather than assumed. | SEC | `aws iam get-user --user-name test-readonly` returns `NoSuchEntity` |

#### Step 1.6: Audit

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.6.1 | Generated and reviewed the IAM credential report | Independently verifies MFA status, key status, and key age for every identity, instead of trusting that setup steps were completed. Found MFA missing on `Andrew` (F-01), which was then fixed. | SEC | `phase-01-iam/results.md` summary. The raw .csv is not committed because it contains account details. |
| 1.6.2 | Created an IAM Access Analyzer using external access analysis, with the current account as the zone of trust | Continuously checks for resources shared outside the account, such as public buckets or cross-account roles. The paid "unused access" analyzer type was deliberately not used (cost decision). | SEC, COST | 0 active findings |

#### Step 1.7: Version control

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.7.1 | Created `.gitignore` before the first commit, excluding `.aws/`, `*.csv`, `*credentials*`, `*.pem`, `*.key`, and `.env` | Prevents credentials, key pairs, and reports from being committed to a public repository. Created first so no secret could slip into the initial commit. | SEC | `.gitignore` |
| 1.7.2 | Created `.gitattributes` forcing LF line endings for `*.sh` | Windows saves files with CRLF line endings, which break Bash scripts on Linux servers. This keeps deployment scripts working on EC2. | OPS, REL | `.gitattributes` |
| 1.7.3 | Reviewed `git status` before every commit | A manual check that only intended files are staged. Caught a folder-structure error before the first commit (F-04). | SEC | Commit history |

</details>

### Phase 2: EC2 Staging Server

**Objective:** Run a staging copy of the website on a virtual server that configures itself from this repository, authenticates without stored credentials, exposes only required network ports, and is fully removed after testing.

**Design principles:**
1. Servers are disposable and rebuilt from code, never hand-configured.
2. No long-lived credentials exist on any server.
3. Network access is limited to what each audience needs.
4. Every resource is torn down and verified after use.

<details>
<summary><b>Show every step and sub-step with rationale</b></summary>

#### Step 2.0: Pre-flight check

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.0.1 | Listed instances, Elastic IPs, and EBS volumes with the CLI | Confirms a clean starting state, so costs and findings from this phase are attributable to this phase only. | COST, OPS | `describe-instances`, `describe-addresses`, `describe-volumes` |
| 2.0.2 | Found and released an unattached Elastic IP in us-east-2 | An Elastic IP bills hourly whether or not it is attached. This one was left over from earlier work in a different region (F-02). | COST | `aws ec2 release-address`, then an empty `describe-addresses --region us-east-2` |
| 2.0.3 | Re-ran all checks in us-east-1 after correcting the CLI default region | The first pass only checked us-east-2. Checks must cover every region where resources may exist (F-03). | OPS | Empty results in us-east-1 |

#### Step 2.1: IAM role for the instance

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.1.1 | Created role `mos-staging-ec2-role` with EC2 as the trusted service | A role gives the instance temporary credentials that AWS rotates automatically, delivered through the instance metadata service. This avoids storing access keys on the server, where they could be stolen if the server is compromised. | SEC | IAM → Roles |
| 2.1.2 | Attached `AmazonSSMManagedInstanceCore` | Allows shell access through AWS Systems Manager Session Manager, an alternative to SSH that needs no open inbound port and logs sessions centrally. | SEC, OPS | Role permissions |
| 2.1.3 | Attached `AmazonS3ReadOnlyAccess` | Gives the role one permission that can be tested from the server to prove the role is working. This is broader than the workload needs (accepted risk R-02). | SEC | Role permissions |

#### Step 2.2: Security group (network firewall)

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.2.1 | Created `mos-staging-sg` in the default VPC | Security groups are stateful firewalls attached to the instance. Only explicitly allowed inbound traffic reaches it. | SEC | EC2 → Security Groups |
| 2.2.2 | Allowed inbound HTTP (TCP 80) from 0.0.0.0/0 | A public website must accept web traffic from any address. | SEC | Inbound rules |
| 2.2.3 | Allowed inbound SSH (TCP 22) from the owner's IP only (/32) | Administrative access is limited to one known address, which removes exposure to internet-wide SSH scanning. Port 22 still being open is accepted risk R-01. | SEC | Inbound rules |
| 2.2.4 | Left outbound rules at the default (all allowed) | The instance must reach package repositories and GitHub during setup. Returning traffic is allowed automatically because security groups are stateful. | OPS | Outbound rules |

#### Step 2.3: User data (automated configuration)

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.3.1 | Wrote `user-data.sh`, which runs once as root at first boot | Configuration as code: every server built from this script is identical, and the script is version-controlled and reviewable. No manual steps means no undocumented changes. | OPS, REL | `phase-02-ec2/user-data.sh` |
| 2.3.2 | Updated packages, then installed Apache (`httpd`) and Git | Starts from current security patches, then installs only what the site needs. | SEC | cloud-init log |
| 2.3.3 | Enabled and started Apache with `systemctl enable --now` | Starts the web server immediately and on every reboot, so the site survives a stop/start without manual action (confirmed in Step 2.6). | REL | `systemctl status httpd` shows active (running) |
| 2.3.4 | Cloned this repository and copied only `site/index.html` into the web root | Deploys from the version-controlled source of truth. Copying only the web content keeps scripts and other repo files from being publicly served. | SEC, OPS | cloud-init log: `Cloning into '/tmp/repo'` |
| 2.3.5 | Built `status.html` from the instance metadata service, using IMDSv2 tokens | Shows which instance, Availability Zone, and instance type served the request, which is useful for troubleshooting and for later load-balancer phases. IMDSv2 requires a session token, protecting against server-side request forgery attacks that could steal role credentials. | SEC, OPS | `http://<ip>/status.html` screenshot |

#### Step 2.4: Instance launch

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.4.1 | Chose the Amazon Linux 2023 AMI | Supported by AWS, receives regular security updates, and includes the AWS CLI. | SEC, OPS | Instance details |
| 2.4.2 | Chose instance type `t3.micro` | Burstable, low-cost, and enough for a low-traffic staging site. Right-sized for the workload. | COST | Instance details |
| 2.4.3 | Created key pair `mos-staging-key` and stored it in `~/.ssh`, outside the repository | Needed for SSH. Kept out of the project folder, and `.gitignore` excludes `*.pem` as a second safeguard. | SEC | Not committed (verified with `git status`) |
| 2.4.4 | Tagged with `Name=mos-staging` and `Project=phase-02` | Tags identify ownership and purpose, support cost tracking by project, and make cleanup checks reliable. | COST, OPS | Instance tags |
| 2.4.5 | Used 8 GiB gp3 root volume with Delete on termination set to Yes | gp3 is the current cost-effective default. Delete on termination prevents orphaned volumes from billing after the instance is gone. | COST | Storage settings |
| 2.4.6 | Attached the IAM instance profile, required IMDSv2, and supplied user data | Applies the controls from Steps 2.1 and 2.3 at launch. | SEC | Advanced details |

#### Step 2.5: Verification

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.5.1 | Confirmed the instance was Running with all status checks passed | Status checks confirm the underlying hardware and the operating system are healthy before testing the application. | REL | EC2 console |
| 2.5.2 | Loaded the site and status page over HTTP | End-to-end proof that the security group, Apache, and deployment all work together. | OPS | `phase-02-ec2/screenshots/` |
| 2.5.3 | Connected over SSH and reviewed `/var/log/cloud-init-output.log` | Confirms user data completed without errors. The log showed packages installed, Apache enabled, the repo cloned, and boot finished in about 38 seconds. | OPS | `phase-02-ec2/results.md` |
| 2.5.4 | Ran `aws sts get-caller-identity` on the instance | Returned `assumed-role/mos-staging-ec2-role/<instance-id>`, proving the instance authenticates through its role. | SEC | `phase-02-ec2/results.md` |
| 2.5.5 | Ran an allowed action (`s3 ls`) and a disallowed one (`iam list-users`) | Proves the role is limited to its attached policies. The IAM call returned `AccessDenied`. | SEC | `phase-02-ec2/results.md` |
| 2.5.6 | Confirmed no `~/.aws/credentials` file exists on the instance | Proves no long-lived keys are stored on the server. The `~/.aws/cli` folder present is the CLI's cache, not credentials. | SEC | `phase-02-ec2/results.md` |

#### Step 2.6: IP addressing test

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.6.1 | Recorded public and private IPs, stopped and started the instance, and recorded them again | Demonstrates that an auto-assigned public IP changes on stop/start while the private IP does not. Anything relying on the public IP would break after a restart. | REL | `phase-02-ec2/results.md` |
| 2.6.2 | Confirmed the site came back without intervention | Validates that Apache was enabled at boot (Step 2.3.3). User data does not re-run on restart. | REL | Browser check |
| 2.6.3 | Allocated an Elastic IP, associated it, and repeated the stop/start | Demonstrates a fixed public address that survives restarts. | REL | `phase-02-ec2/results.md` |
| 2.6.4 | Disassociated and released the Elastic IP immediately | Elastic IPs bill hourly. In production, DNS or a load balancer is preferred over relying on Elastic IPs. | COST | Empty `describe-addresses` |

#### Step 2.7: Teardown

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.7.1 | Terminated the instance | The server is disposable and can be rebuilt from `user-data.sh` in minutes, so there is no reason to pay for idle capacity. | COST | Instance state `terminated` |
| 2.7.2 | Verified no instances, Elastic IPs, or volumes remained, using the CLI | Confirms cleanup instead of assuming it. Orphaned IPs and volumes are the most common source of surprise charges. | COST | `describe-instances`, `describe-addresses`, `describe-volumes` |
| 2.7.3 | Kept the IAM role, security group, and key pair | These cost nothing and will be reused in Phase 3. | COST | Listed in IAM and EC2 |

#### Step 2.8: Documentation

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.8.1 | Committed the user data script, results, screenshots, and phase README | Creates a reviewable record of the build and its proof. | OPS | `phase-02-ec2/` |
| 2.8.2 | Reviewed `git status` for key pairs before committing | Confirms no `.pem` file was staged. | SEC | Commit history |

</details>

### Phase 3: EC2 Storage

**Objective:** Separate the website's content from the server that serves it, so content survives server loss, can be backed up and moved between Availability Zones, can be baked into a reusable image, and can be shared by several servers at once.

**Design principles:**
1. Content lives on storage that outlives any one server.
2. All data at rest is encrypted by default.
3. Backups are proven by restoring them, not assumed.
4. Shared storage only accepts traffic from the web tier's security group.
5. Every storage resource is deleted and verified after use, in dependency order.

<details>
<summary><b>Show every step and sub-step with rationale</b></summary>

#### Step 3.0: Fresh start

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 3.0.1 | Listed instances, volumes, snapshots, AMIs, Elastic IPs, and EFS file systems | Course labs commonly leave snapshots and AMIs that bill monthly. Confirms costs from this phase are attributable to it. | COST | All empty in us-east-1 |
| 3.0.2 | Confirmed the role, security group, and key pair from Phase 2 still existed | Reuse avoids rebuilding known-good, already-reviewed configuration. | OPS | `get-role`, `describe-security-groups` returned values |
| 3.0.3 | Enabled EBS encryption by default for us-east-1 | Every new volume and snapshot is encrypted at rest with no per-volume step that could be forgotten. Free, and transparent to the instance. | SEC | `aws ec2 get-ebs-encryption-by-default` returns `true` |

#### Step 3.1: Web server rebuilt from code

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 3.1.1 | Launched `mos-web-1` in us-east-1a from the Phase 2 user data script | Proves the server is reproducible from version-controlled code after a full account cleanup. | OPS, REL | Site loads; status page shows us-east-1a |
| 3.1.2 | Corrected the console region before launching | Security groups and key pairs are regional; launching in the wrong region would create a disconnected stack (F-06). | OPS | Subnet list shows us-east-1 AZs |
| 3.1.3 | Tagged `Project=phase-03` on instance and volumes | Makes every resource from this phase easy to find during teardown and cost review. | COST | Instance and volume tags |

#### Step 3.2: Dedicated EBS data volume

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 3.2.1 | Created a 1 GiB encrypted gp3 volume `mos-site-data` in us-east-1a | Separates content from the OS disk. An EBS volume can only attach in its own AZ, so it was created alongside the instance. Sized to the workload. | REL, COST | Volume in us-east-1a, Encrypted |
| 3.2.2 | Confirmed the volume was blank with `file -s` before formatting with XFS | Formatting erases data. Checking first prevents wiping a volume that already holds content. | REL | `file -s` returned `data` |
| 3.2.3 | Backed up the web root, mounted the volume over `/var/www/html`, and restored the files | Moves the live site onto the new volume without downtime or data loss. | REL | `df -h` shows `/dev/nvme1n1` on `/var/www/html` |
| 3.2.4 | Diagnosed a browser timeout | `curl localhost` returned 200, proving the server was healthy and isolating the fault to the network. Found the wrong security group (F-07). | SEC, OPS | `curl -I` output, `describe-instances` |
| 3.2.5 | Added an fstab entry by UUID with `nofail`, then tested with `umount` and `mount -a` | The UUID never changes, unlike `nvme` device names. `nofail` lets the server boot even if the volume is missing. Testing the entry before rebooting avoids an unbootable server. | REL | fstab line, `mount -a` with no errors |
| 3.2.6 | Rebooted and re-checked | Proves the mount and web server both return automatically. | REL | `/volume.html` loads after reboot |

#### Step 3.3: Snapshot backup and cross-AZ restore

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 3.3.1 | Took a snapshot of `mos-site-data` | Snapshots are stored regionally and can be restored into any AZ, which is how EBS data is backed up and moved. | REL | Snapshot status Completed |
| 3.3.2 | Created `after.html` after the snapshot started | Gives a test that distinguishes a point-in-time copy from a live copy. | REL | File present on web 1 |
| 3.3.3 | Launched `mos-web-2` in us-east-1b and restored the snapshot to a new volume in us-east-1b | Demonstrates recovery of the site's data in a different AZ. | REL | Volume and instance both in us-east-1b |
| 3.3.4 | Attached the restored volume and verified the OS saw it | A volume must be attached before the OS can use it (F-09). | OPS | `lsblk` shows a 1 GiB `nvme1n1` |
| 3.3.5 | Checked `file -s` and mounted without formatting | `XFS filesystem data` confirms existing content. Running `mkfs` here would have destroyed the backup. Found missing user data (F-08). | REL | `file -s` output, cloud-init log |
| 3.3.6 | Loaded `/volume.html`, `/after.html`, and `/status.html` | Pass/fail proof: the snapshot content arrived, later changes did not, and the data came from web 1. | REL | volume.html loads, after.html 404, status shows us-east-1a |
| 3.3.7 | Terminated `mos-web-2` and deleted the restored volume | Added volumes do not delete on termination by default and would keep billing. | COST | Volume deleted |

#### Step 3.4: Golden AMI

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 3.4.1 | Created `mos-web-golden-v1` from `mos-web-1` with reboot enabled | Captures a fully configured server, including its data volume. The reboot gives a consistent image. | REL, OPS | AMI status Available, two backing snapshots |
| 3.4.2 | Launched an instance from the AMI in us-east-1b with no user data | Proves new servers can start ready to serve without installing anything, which is the basis for Auto Scaling in Phase 4. | REL | Site and volume.html load immediately |
| 3.4.3 | Noted the status page still showed us-east-1a | Anything generated at build time is frozen into the image (F-10). | OPS | Browser check |

#### Step 3.5: Shared storage with EFS

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 3.5.1 | Created `mos-efs-sg` allowing NFS (2049) only from `mos-staging-sg` | Referencing a security group instead of an IP range lets any web server in that group connect, and nothing else, no matter how many servers exist or what their IPs are. | SEC | Inbound rule source is `mos-staging-sg` |
| 3.5.2 | Created Regional file system `mos-shared` with mount targets in us-east-1a and us-east-1b using `mos-efs-sg` | Regional EFS is multi-AZ. The default security group was replaced so access follows rule 3.5.1. Automatic backups were turned off for cost (R-06). | SEC, REL, COST | Mount targets Available |
| 3.5.3 | Installed `amazon-efs-utils` and mounted with `-o tls` on both servers | The EFS helper handles the mount, and `tls` encrypts data in transit between server and file system. | SEC | `df -h` on both servers |
| 3.5.4 | Wrote a page from web 1, then edited it from the AMI server | Proves both servers in different AZs read and write the same files, which is what lets servers behind a load balancer show the same site. | REL | `/shared/` identical on both servers after each edit |

#### Step 3.6: Teardown

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 3.6.1 | Terminated all instances | Servers are disposable and reproducible from code or the AMI. | COST | Instances terminated |
| 3.6.2 | Deleted all available volumes | Data volumes and the AMI's data volume were not set to delete on termination. | COST | `describe-volumes` empty |
| 3.6.3 | Deregistered the AMI, then deleted all snapshots | AWS blocks deleting a snapshot that an AMI still uses, so order matters. | COST | `describe-images` and `describe-snapshots` empty |
| 3.6.4 | Deleted the EFS file system, then `mos-efs-sg` and leftover `launch-wizard` groups | Mount targets must be gone before their security group can be deleted. Removing unused groups keeps the account auditable. | COST, SEC | `describe-file-systems` empty |
| 3.6.5 | Kept the role, `mos-staging-sg`, key pair, and encryption setting | Free, reviewed, and reused in Phase 4. | COST | Listed in IAM and EC2 |

</details>

### Phase 4: Load Balancing and Auto Scaling

**Objective:** Serve the site through a single load balancer in front of servers in two Availability Zones, so that a failed server is detected and replaced automatically, load is spread evenly, and capacity grows with demand.

**Design principles:**
1. Visitors reach servers only through the load balancer.
2. Every server is launched from one versioned template, so no setting can be forgotten.
3. Health is judged by whether the website answers, not just whether the server is on.
4. Capacity is spread across two AZs and never drops below two servers.
5. Teardown follows dependency order, starting with the Auto Scaling group.

<details>
<summary><b>Show every step and sub-step with rationale</b></summary>

#### Step 4.1: Pre-flight check

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 4.1.1 | Confirmed no instances, load balancers, target groups, Auto Scaling groups, or launch templates existed | A leftover Auto Scaling group relaunches anything you terminate, and a load balancer bills hourly even when idle. | COST | Empty `describe-*` output |
| 4.1.2 | Confirmed the IAM role and EBS encryption by default still existed | Reuses reviewed configuration from earlier phases. | SEC, OPS | Role ARN returned; encryption `true` |

#### Step 4.2: Chained security groups

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 4.2.1 | Created `mos-alb-sg` allowing HTTP from anywhere | The load balancer is the only public entry point. | SEC | Inbound rule 80 from 0.0.0.0/0 |
| 4.2.2 | Created `mos-web-sg` allowing HTTP only from `mos-alb-sg`, and SSH only from the EC2 Instance Connect prefix list | Referencing the load balancer's security group (not its IPs, which change) means servers can't be reached by going around it. SSH is limited to AWS's Instance Connect service. | SEC | `UserIdGroupPairs` shows `mos-alb-sg`; port 22 shows `pl-0e4b...` |
| 4.2.3 | Verified both groups with the CLI after each change | Caught the wrong prefix list (F-11) and a broken HTTP rule (F-12) before anything launched. | SEC, OPS | `describe-security-groups` output |

#### Step 4.3: User data with a per-boot status page

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 4.3.1 | Wrote `user-data.sh` to install Apache and Git and deploy the site from this repo | Every server is built identically from version-controlled code. | OPS, REL | `phase-04-elb-asg/user-data.sh` |
| 4.3.2 | Installed a script in `/var/lib/cloud/scripts/per-boot/` that rebuilds `status.html` from instance metadata (IMDSv2) | User data runs once; per-boot scripts run on every start, so the page is always accurate. Closes F-10. | OPS | Each server reported its own AZ in Step 4.8 |
| 4.3.3 | Omitted `dnf update` | Faster boots help new servers pass health checks within the grace period. Accepted as R-08. | REL | Healthy ~3 min after launch |
| 4.3.4 | Saved the script with LF line endings | Windows CRLF endings break the `#!/bin/bash` line on Linux. | OPS | VS Code status bar |

#### Step 4.4: Launch template

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 4.4.1 | Created `mos-web-lt`: Amazon Linux 2023, t3.micro, `mos-web-sg` only, IAM role, IMDSv2 required, user data, no subnet | One saved definition removes the launch mistakes from Phase 3 (F-07, F-08). Subnets are left to the Auto Scaling group. | SEC, OPS | `describe-launch-template-versions` |
| 4.4.2 | Tagged instances and volumes `Project=phase-04` | Supports cost tracking and teardown checks. | COST | Template tags |
| 4.4.3 | Created version 2 and set it as the default | Launch templates are versioned, not edited in place, which allows rollback. The trigger was a false alarm from a check that read the wrong field (F-15). | OPS | Both versions show the role ARN |

#### Step 4.5: Target group and health check

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 4.5.1 | Created `mos-web-tg` (HTTP:80, instances) from the CLI | The CLI produces an exact, repeatable record of the configuration (F-14). | OPS | `create-target-group` command in `commands.ps1` |
| 4.5.2 | Health check on `/index.html`, 10 s interval, 2 to pass, 2 to fail, 200 OK only | Checks that the real site loads, not just that a port is open. Detects failure in about 20 seconds instead of the default minutes. | REL | Target group settings |
| 4.5.3 | Registered no targets by hand | The Auto Scaling group registers and deregisters servers automatically. | OPS | Empty target list at creation |

#### Step 4.6: Application Load Balancer

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 4.6.1 | Created internet-facing `mos-web-alb` in us-east-1a and us-east-1b with only `mos-alb-sg` | Two AZs keep the entry point available if one AZ fails. The default security group was removed so access follows Step 4.2. | REL, SEC | Load balancer settings |
| 4.6.2 | Listener HTTP:80 forwards to `mos-web-tg` | Single front door for all servers. The console's **Not reachable** warning exposed a missing rule (F-13) before any visitor was affected. | REL | Listener rules |

#### Step 4.7: Auto Scaling group

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 4.7.1 | Created `mos-web-asg` from the template's default version, in us-east-1a and us-east-1b | Spreads servers across AZs; if one AZ fails, replacements launch in the other. | REL | Instances in both AZs |
| 4.7.2 | Attached to `mos-web-tg` and turned on ELB health checks | With EC2 checks alone, a server whose website crashed would stay in service. ELB checks replace it. | REL | Group health check type ELB |
| 4.7.3 | Set a 120-second health check grace period | User data needs time to finish before a new server is judged; without it, new servers would be killed while booting. | REL | ~3 min to healthy, no false terminations |
| 4.7.4 | Set min 2, desired 2, max 4 | Two servers minimum for availability; headroom to scale; a cap on cost. | REL, COST | Group capacity settings |

#### Step 4.8: Load balancing verification

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 4.8.1 | Requested `/status.html` through the ALB 10 times | Shows requests spread across both AZs (round robin) and confirms F-10 is fixed. | REL | Alternating us-east-1a / us-east-1b |
| 4.8.2 | Opened a server's public IP directly | Proves `mos-web-sg` blocks traffic that bypasses the load balancer. | SEC | Connection timed out |

#### Step 4.9: Self-healing test

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 4.9.1 | Stopped Apache on one server | Simulates an application failure on a server whose hardware is fine. | REL | `systemctl stop httpd` |
| 4.9.2 | Watched target health and scaling activity | Unhealthy in ~20 s; the ALB stopped routing to it; Auto Scaling terminated it with connection draining and launched a replacement 1 second later; healthy ~3 min after. The site stayed up throughout. | REL | Scaling activity: "ELB system health check failure" |

#### Step 4.10: Scaling policy and load test

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 4.10.1 | Created target tracking policy `mos-cpu-50` (average CPU 50%, 120 s warmup) | Keeps average CPU near a target; AWS manages the CloudWatch alarms. Recommended for most workloads. | REL, COST | AlarmHigh and AlarmLow created |
| 4.10.2 | Generated load with `stress-ng` under `nohup` on both servers | `nohup` keeps the load running after the session closes; both servers are needed because the policy uses the group average. | REL | CPU datapoints |
| 4.10.3 | Diagnosed a flat 50% average | One server at 100% and one at 0% averages exactly 50%, which never exceeds the target (F-16). | OPS | CloudWatch metric output |
| 4.10.4 | Observed scale-out | AlarmHigh fired and the policy raised desired capacity from 2 to 3; a third server launched and passed checks. | REL | Scaling activity naming `mos-cpu-50` |

#### Step 4.11: Teardown

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 4.11.1 | Deleted the load balancer, target group, and launch template | The load balancer bills hourly; the target group can't be deleted while a listener uses it. | COST | Empty `describe-*` output |
| 4.11.2 | Force-deleted the Auto Scaling group after verification showed it still running | A live group keeps replacing servers. The correct order is the group first (F-17). Deleting it also removed its scaling policy and alarms. | COST | Empty group, instance, volume, and alarm lists |
| 4.11.3 | Kept both security groups and the IAM role | Free, reviewed, and reusable. | COST | Listed in EC2 and IAM |

</details>

### Change Log

| Date | Change |
|---|---|
| 2026-10-17 | Phase 1 completed and committed |
| 2026-10-19 | Phase 2 completed and committed. F-02 and F-03 found and resolved. |
| 2026-10-21 | Phase 3 completed. EBS encryption by default enabled. F-06 to F-10 found; F-06 to F-09 resolved. |
| 2026-10-23 | Phase 4 completed. F-10 closed; F-11 to F-17 found and resolved. |