# Phase 1: IAM & CLI Secure Baseline

## What I built
- Secured the root user with MFA and confirmed it has no access keys
- Created an `admin` group with AdministratorAccess and a daily-use IAM user (`Andrew`) in it
- Set up budget alerts to catch unexpected charges
- Configured the AWS CLI and ran a least-privilege lab: a custom S3 read-only policy attached to a test user

## Why it matters
- Root can do anything, so it's locked away and only used for rare account tasks
- Permissions come from groups, not individual users, so access is easier to manage as people are added
- Least privilege limits the damage if a credential is ever leaked

## How I proved it
- The test user could list S3 buckets but got `AccessDenied` on `iam:ListUsers` and `s3:CreateBucket` (implicit deny)
- Credential report reviewed; found MFA missing on my daily user and fixed it
- IAM Access Analyzer: 0 external access findings
- Test user deleted and cleanup verified (`NoSuchEntity`)
- Full outputs in [results.md](results.md)

## What I'd do differently in production
- Use IAM Identity Center for short-lived credentials instead of long-lived access keys
- Enforce MFA with an IAM policy instead of relying on each user to set it up