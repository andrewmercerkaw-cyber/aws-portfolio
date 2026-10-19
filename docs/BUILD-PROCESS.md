# Build Process and Audit Record

**Project:** Small-business website on AWS (Mo's Custom Creations)
**Owner:** Andrew
**Account region:** us-east-1 (N. Virginia)
**Scope of this record:** Phase 1 (account security baseline) and Phase 2 (EC2 staging server)

This document breaks the build into steps and sub-steps. For each one it records **what was done**, **why it was done**, and **where the evidence is**, so a reviewer can trace every decision and verify the result. Deviations, findings, and accepted risks are listed in their own sections instead of being hidden.

**Reference frameworks:** decisions map to the [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) pillars, noted in each table as **SEC** (Security), **COST** (Cost Optimization), **REL** (Reliability), and **OPS** (Operational Excellence).

---

## Phase 1: Account Security Baseline

**Objective:** Secure the AWS account before any workloads exist, so every later phase is built on controlled access, monitored spending, and auditable identities.

**Design principles:**
1. The root user is never used for daily work.
2. Every human identity has MFA.
3. Permissions are granted through groups, not to individual users.
4. Every identity gets the least privilege it needs.
5. Spending is monitored from day one.

### Step 1.1: Secure the root user

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.1.1 | Enabled MFA on the root user | Root has unrestricted access to the account, including billing and closing the account. A stolen root password without MFA is the worst-case compromise. | SEC | Credential report: `<root_account>` `mfa_active = true` |
| 1.1.2 | Confirmed no root access keys exist | Root access keys cannot be restricted by IAM policy. If leaked, they give programmatic full control of the account. AWS guidance is that root should never have keys. | SEC | Credential report: `access_key_1_active = false`, `access_key_2_active = false` |
| 1.1.3 | Stored root credentials in a password manager and stopped using root | Limits root use to the few tasks only root can perform, which reduces exposure. | SEC | Root `password_last_used` stops advancing after setup |

### Step 1.2: Account-level settings

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.2.1 | Activated IAM user and role access to billing information | By default, even administrator IAM users cannot view billing or create budgets. Without this, cost monitoring would require signing in as root, which breaks principle 1. | SEC, COST | Admin IAM user can open Billing and Cost Management |
| 1.2.2 | Set an account password policy | Enforces password strength and prevents reuse for all IAM users with console access. | SEC | IAM → Account settings → Password policy |
| 1.2.3 | Created an account alias | Gives IAM users a readable sign-in URL. A convenience step, not a security control. | OPS | IAM dashboard shows alias |

### Step 1.3: Administrative identity

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.3.1 | Created an `admin` group with the AWS-managed `AdministratorAccess` policy | Permissions attached to a group apply to every member. Adding or removing a person becomes a membership change instead of rebuilding permissions, which reduces error and makes access easy to review. | SEC, OPS | `aws iam list-attached-group-policies --group-name admin` |
| 1.3.2 | Used IAM user `Andrew` as the daily administrator, as a member of `admin` | Separates daily work from root. All actions are attributed to a named identity in logs. | SEC | `aws iam list-groups-for-user --user-name Andrew` returns `admin` |
| 1.3.3 | Enabled MFA on `Andrew` | The daily admin has full permissions through the group, so it needs the same protection as root. Initially missed, then found and fixed during the audit in Step 1.6 (finding F-01). | SEC | Credential report, after remediation |

### Step 1.4: Cost controls

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.4.1 | Created an AWS Budget with email alerts | Detects unexpected spending, such as a forgotten instance or unattached IP address, within hours instead of at month end. Created before any compute was launched. | COST | Billing → Budgets |
| 1.4.2 | Reviewed the bill by service | Established a cost baseline and identified charges from earlier resources. This led to the decision to tear down rather than leave idle infrastructure running. | COST | Billing → Bills → Charges by service |

### Step 1.5: Command-line access and least-privilege test

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.5.1 | Configured AWS CLI v2 with `Andrew`'s access key | Lets infrastructure be managed with repeatable, recordable commands instead of manual console clicks. | OPS | `aws sts get-caller-identity` returns `user/Andrew` |
| 1.5.2 | Set the CLI default region to us-east-1 | The default was us-east-2, while existing resources were in us-east-1. A mismatched default causes resources to be missed during checks (finding F-03). | OPS | `aws configure get region` returns `us-east-1` |
| 1.5.3 | Wrote a custom policy `S3ReadOnlyLab` allowing only `s3:ListAllMyBuckets`, `s3:ListBucket`, `s3:GetObject` | Demonstrates least privilege: an identity gets only the specific actions it needs. Written as a version-controlled JSON file so the policy is reviewable. | SEC | `phase-01-iam/s3-readonly-lab.json` |
| 1.5.4 | Created test user `test-readonly`, attached the policy, and configured a separate CLI profile | Isolates the test identity from the admin identity so results reflect only the custom policy. | SEC | `phase-01-iam/commands.ps1` |
| 1.5.5 | Ran one allowed and two disallowed actions as the test user | Proves the policy works by showing both what is allowed and what is denied. `iam:ListUsers` and `s3:CreateBucket` returned `AccessDenied` because no policy allowed them (implicit deny). | SEC | `phase-01-iam/results.md` |
| 1.5.6 | Deleted the test user's access key, detached the policy, deleted the user, and removed the local profile | Unused identities with active keys are a common source of breaches. Order matters: AWS will not delete a user with keys or policies still attached. Deletion was verified rather than assumed. | SEC | `aws iam get-user --user-name test-readonly` returns `NoSuchEntity` |

### Step 1.6: Audit

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.6.1 | Generated and reviewed the IAM credential report | Independently verifies MFA status, key status, and key age for every identity, instead of trusting that setup steps were completed. Found MFA missing on `Andrew` (F-01), which was then fixed. | SEC | `phase-01-iam/results.md` summary. The raw .csv is not committed because it contains account details. |
| 1.6.2 | Created an IAM Access Analyzer using external access analysis, with the current account as the zone of trust | Continuously checks for resources shared outside the account, such as public buckets or cross-account roles. The paid "unused access" analyzer type was deliberately not used (cost decision). | SEC, COST | 0 active findings |

### Step 1.7: Version control

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 1.7.1 | Created `.gitignore` before the first commit, excluding `.aws/`, `*.csv`, `*credentials*`, `*.pem`, `*.key`, and `.env` | Prevents credentials, key pairs, and reports from being committed to a public repository. Created first so no secret could slip into the initial commit. | SEC | `.gitignore` |
| 1.7.2 | Created `.gitattributes` forcing LF line endings for `*.sh` | Windows saves files with CRLF line endings, which break Bash scripts on Linux servers. This keeps deployment scripts working on EC2. | OPS, REL | `.gitattributes` |
| 1.7.3 | Reviewed `git status` before every commit | A manual check that only intended files are staged. Caught a folder-structure error before the first commit (F-04). | SEC | Commit history |

---

## Phase 2: EC2 Staging Server

**Objective:** Run a staging copy of the website on a virtual server that configures itself from this repository, authenticates without stored credentials, exposes only required network ports, and is fully removed after testing.

**Design principles:**
1. Servers are disposable and rebuilt from code, never hand-configured.
2. No long-lived credentials exist on any server.
3. Network access is limited to what each audience needs.
4. Every resource is torn down and verified after use.

### Step 2.0: Pre-flight check

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.0.1 | Listed instances, Elastic IPs, and EBS volumes with the CLI | Confirms a clean starting state, so costs and findings from this phase are attributable to this phase only. | COST, OPS | `describe-instances`, `describe-addresses`, `describe-volumes` |
| 2.0.2 | Found and released an unattached Elastic IP in us-east-2 | An Elastic IP bills hourly whether or not it is attached. This one was left over from earlier work in a different region (F-02). | COST | `aws ec2 release-address`, then an empty `describe-addresses --region us-east-2` |
| 2.0.3 | Re-ran all checks in us-east-1 after correcting the CLI default region | The first pass only checked us-east-2. Checks must cover every region where resources may exist (F-03). | OPS | Empty results in us-east-1 |

### Step 2.1: IAM role for the instance

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.1.1 | Created role `mos-staging-ec2-role` with EC2 as the trusted service | A role gives the instance temporary credentials that AWS rotates automatically, delivered through the instance metadata service. This avoids storing access keys on the server, where they could be stolen if the server is compromised. | SEC | IAM → Roles |
| 2.1.2 | Attached `AmazonSSMManagedInstanceCore` | Allows shell access through AWS Systems Manager Session Manager, an alternative to SSH that needs no open inbound port and logs sessions centrally. | SEC, OPS | Role permissions |
| 2.1.3 | Attached `AmazonS3ReadOnlyAccess` | Gives the role one permission that can be tested from the server to prove the role is working. This is broader than the workload needs (accepted risk R-02). | SEC | Role permissions |

### Step 2.2: Security group (network firewall)

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.2.1 | Created `mos-staging-sg` in the default VPC | Security groups are stateful firewalls attached to the instance. Only explicitly allowed inbound traffic reaches it. | SEC | EC2 → Security Groups |
| 2.2.2 | Allowed inbound HTTP (TCP 80) from 0.0.0.0/0 | A public website must accept web traffic from any address. | SEC | Inbound rules |
| 2.2.3 | Allowed inbound SSH (TCP 22) from the owner's IP only (/32) | Administrative access is limited to one known address, which removes exposure to internet-wide SSH scanning. Port 22 still being open is accepted risk R-01. | SEC | Inbound rules |
| 2.2.4 | Left outbound rules at the default (all allowed) | The instance must reach package repositories and GitHub during setup. Returning traffic is allowed automatically because security groups are stateful. | OPS | Outbound rules |

### Step 2.3: User data (automated configuration)

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.3.1 | Wrote `user-data.sh`, which runs once as root at first boot | Configuration as code: every server built from this script is identical, and the script is version-controlled and reviewable. No manual steps means no undocumented changes. | OPS, REL | `phase-02-ec2/user-data.sh` |
| 2.3.2 | Updated packages, then installed Apache (`httpd`) and Git | Starts from current security patches, then installs only what the site needs. | SEC | cloud-init log |
| 2.3.3 | Enabled and started Apache with `systemctl enable --now` | Starts the web server immediately and on every reboot, so the site survives a stop/start without manual action (confirmed in Step 2.6). | REL | `systemctl status httpd` shows active (running) |
| 2.3.4 | Cloned this repository and copied only `site/index.html` into the web root | Deploys from the version-controlled source of truth. Copying only the web content keeps scripts and other repo files from being publicly served. | SEC, OPS | cloud-init log: `Cloning into '/tmp/repo'` |
| 2.3.5 | Built `status.html` from the instance metadata service, using IMDSv2 tokens | Shows which instance, Availability Zone, and instance type served the request, which is useful for troubleshooting and for later load-balancer phases. IMDSv2 requires a session token, protecting against server-side request forgery attacks that could steal role credentials. | SEC, OPS | `http://<ip>/status.html` screenshot |

### Step 2.4: Instance launch

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.4.1 | Chose the Amazon Linux 2023 AMI | Supported by AWS, receives regular security updates, and includes the AWS CLI. | SEC, OPS | Instance details |
| 2.4.2 | Chose instance type `t3.micro` | Burstable, low-cost, and enough for a low-traffic staging site. Right-sized for the workload. | COST | Instance details |
| 2.4.3 | Created key pair `mos-staging-key` and stored it in `~/.ssh`, outside the repository | Needed for SSH. Kept out of the project folder, and `.gitignore` excludes `*.pem` as a second safeguard. | SEC | Not committed (verified with `git status`) |
| 2.4.4 | Tagged with `Name=mos-staging` and `Project=phase-02` | Tags identify ownership and purpose, support cost tracking by project, and make cleanup checks reliable. | COST, OPS | Instance tags |
| 2.4.5 | Used 8 GiB gp3 root volume with Delete on termination set to Yes | gp3 is the current cost-effective default. Delete on termination prevents orphaned volumes from billing after the instance is gone. | COST | Storage settings |
| 2.4.6 | Attached the IAM instance profile, required IMDSv2, and supplied user data | Applies the controls from Steps 2.1 and 2.3 at launch. | SEC | Advanced details |

### Step 2.5: Verification

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.5.1 | Confirmed the instance was Running with all status checks passed | Status checks confirm the underlying hardware and the operating system are healthy before testing the application. | REL | EC2 console |
| 2.5.2 | Loaded the site and status page over HTTP | End-to-end proof that the security group, Apache, and deployment all work together. | OPS | `phase-02-ec2/screenshots/` |
| 2.5.3 | Connected over SSH and reviewed `/var/log/cloud-init-output.log` | Confirms user data completed without errors. The log showed packages installed, Apache enabled, the repo cloned, and boot finished in about 38 seconds. | OPS | `phase-02-ec2/results.md` |
| 2.5.4 | Ran `aws sts get-caller-identity` on the instance | Returned `assumed-role/mos-staging-ec2-role/<instance-id>`, proving the instance authenticates through its role. | SEC | `phase-02-ec2/results.md` |
| 2.5.5 | Ran an allowed action (`s3 ls`) and a disallowed one (`iam list-users`) | Proves the role is limited to its attached policies. The IAM call returned `AccessDenied`. | SEC | `phase-02-ec2/results.md` |
| 2.5.6 | Confirmed no `~/.aws/credentials` file exists on the instance | Proves no long-lived keys are stored on the server. The `~/.aws/cli` folder present is the CLI's cache, not credentials. | SEC | `phase-02-ec2/results.md` |

### Step 2.6: IP addressing test

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.6.1 | Recorded public and private IPs, stopped and started the instance, and recorded them again | Demonstrates that an auto-assigned public IP changes on stop/start while the private IP does not. Anything relying on the public IP would break after a restart. | REL | `phase-02-ec2/results.md` |
| 2.6.2 | Confirmed the site came back without intervention | Validates that Apache was enabled at boot (Step 2.3.3). User data does not re-run on restart. | REL | Browser check |
| 2.6.3 | Allocated an Elastic IP, associated it, and repeated the stop/start | Demonstrates a fixed public address that survives restarts. | REL | `phase-02-ec2/results.md` |
| 2.6.4 | Disassociated and released the Elastic IP immediately | Elastic IPs bill hourly. In production, DNS or a load balancer is preferred over relying on Elastic IPs. | COST | Empty `describe-addresses` |

### Step 2.7: Teardown

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.7.1 | Terminated the instance | The server is disposable and can be rebuilt from `user-data.sh` in minutes, so there is no reason to pay for idle capacity. | COST | Instance state `terminated` |
| 2.7.2 | Verified no instances, Elastic IPs, or volumes remained, using the CLI | Confirms cleanup instead of assuming it. Orphaned IPs and volumes are the most common source of surprise charges. | COST | `describe-instances`, `describe-addresses`, `describe-volumes` |
| 2.7.3 | Kept the IAM role, security group, and key pair | These cost nothing and will be reused in Phase 3. | COST | Listed in IAM and EC2 |

### Step 2.8: Documentation

| Sub-step | Action | Why | Pillar | Evidence |
|---|---|---|---|---|
| 2.8.1 | Committed the user data script, results, screenshots, and phase README | Creates a reviewable record of the build and its proof. | OPS | `phase-02-ec2/` |
| 2.8.2 | Reviewed `git status` for key pairs before committing | Confirms no `.pem` file was staged. | SEC | Commit history |

---

## Findings Register

Issues discovered during the build and how each was resolved.

| ID | Finding | Severity | How found | Resolution | Status |
|---|---|---|---|---|---|
| F-01 | Daily admin user `Andrew` had no MFA | High | Credential report (Step 1.6.1) | MFA device assigned and confirmed at sign-in | Closed |
| F-02 | Unattached Elastic IP left in us-east-2, incurring hourly charges | Low | Pre-flight check (Step 2.0.2) | Released with `aws ec2 release-address` and verified | Closed |
| F-03 | CLI default region (us-east-2) did not match the working region (us-east-1), so checks missed resources | Medium | Pre-flight check (Step 2.0.3) | Default region changed to us-east-1. Checks now name the region explicitly when needed. | Closed |
| F-04 | `.gitignore` initially created as a folder instead of a file, so ignore rules were not active | Medium | `git status` review before first commit (Step 1.7.3) | Files moved to the repository root and re-verified before committing | Closed |
| F-05 | Direct `IAMReadOnlyAccess` policy on `Andrew` duplicates permissions already granted by the `admin` group | Low | Policy review (Step 1.3) | Detach with `aws iam detach-user-policy` so all permissions come from the group | Verify |

## Accepted Risks

Known gaps that are acceptable for a short-lived lab, with the planned production fix.

| ID | Risk | Why accepted | Production remediation |
|---|---|---|---|
| R-01 | SSH port 22 open to the owner's IP | Short-lived instance, single /32 source, key-based authentication only | Close port 22 and use Session Manager exclusively |
| R-02 | `AmazonS3ReadOnlyAccess` grants read access to every bucket, which is more than the workload needs | Used only to prove the role works, and no buckets exist | Replace with a custom policy scoped to specific buckets, or remove it |
| R-03 | The site is served over HTTP, not HTTPS | Staging only, no user data collected | Add a TLS certificate (AWS Certificate Manager) on a load balancer or CloudFront |
| R-04 | The admin user uses a long-lived CLI access key | Single user, key used from one machine | Move to IAM Identity Center with short-lived credentials, then deactivate the key. Deferred because enabling it creates an AWS Organization, which affects account plan and credit eligibility. |
| R-05 | Single instance, single Availability Zone | Staging only | Load balancer plus Auto Scaling across multiple Availability Zones (Phase 3) |

## Change Log

| Date | Change |
|---|---|
| 2026-10-17 | Phase 1 completed and committed |
| 2026-10-19 | Phase 2 completed and committed. F-02 and F-03 found and resolved. |
