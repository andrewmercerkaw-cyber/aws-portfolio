# Phase 3: EC2 Storage

## What I built
The Mo's Custom Creations web server, rebuilt from code, with the website moved onto
storage that outlives the server:

- **A dedicated EBS data volume** (1 GiB, gp3, encrypted) mounted at the web root and set
  to remount automatically on every boot
- **A snapshot backup** of that volume, restored into a second Availability Zone and
  attached to a new server
- **A golden AMI** of the configured server, used to launch a new server that served the
  site immediately with no setup script
- **Amazon EFS shared storage** mounted on two servers in two Availability Zones, so one
  edit appears on both
- **EBS encryption by default** turned on for the region

## Why it matters
- **Content survives server loss.** If a server is terminated, the data volume keeps the site.
- **Backups are proven, not assumed.** The snapshot was restored in a different AZ and
  checked page by page.
- **Faster, more reliable launches.** A golden AMI starts ready to serve, which is what
  Auto Scaling needs in Phase 4.
- **Shared content for multiple servers.** EFS lets several servers behind a load balancer
  show the same site.
- **Security by default.** Data at rest is encrypted automatically, EFS traffic is encrypted
  in transit, and EFS only accepts connections from the web servers' security group.

## How I proved it
- `file -s` showed a blank volume (`data`) before formatting and a restored volume
  (`XFS filesystem data`) before mounting, so nothing was formatted by mistake
- The site served from the data volume before and after a reboot
- On the restored server in us-east-1b, `/volume.html` loaded, `/after.html` (created after
  the snapshot) returned 404, and the status page still showed us-east-1a, proving the data
  came from the snapshot
- A server launched from the AMI with no user data served the site immediately
- A page written on one server through EFS appeared on the other, and an edit made from the
  second server appeared on the first
- Every resource was deleted in dependency order and verified empty with the CLI

Full outputs are in [results.md](results.md), commands in [commands.sh](commands.sh), and
screenshots in [screenshots/](screenshots/).

## What went wrong and how I fixed it
| Problem | How I found it | Fix |
|---|---|---|
| Console set to the wrong region | Subnet list showed `us-east-2b` | Switched to N. Virginia before creating anything |
| Server launched with the wrong security group, so the site timed out | `curl localhost` worked but the browser timed out; `describe-instances` showed `launch-wizard-2` | Swapped to `mos-staging-sg` and deleted the extra group |
| Second server launched without user data | cloud-init log finished in 11 seconds with no installs | Installed Apache manually |
| Restored volume not attached | `lsblk` showed only the root disk | Attached it with `aws ec2 attach-volume` |
| Status page showed the original server's AZ on copies | Browser check | Known issue; will regenerate it at boot in Phase 4 |

## What I'd do differently in production
- Use a **launch template** so the security group, role, and user data can't be forgotten
  at launch (Phase 4)
- Add the EFS mount to fstab with `_netdev,tls`, or mount it from user data, so it survives
  reboots
- Keep EFS automatic backups on, or manage backups with AWS Backup
- Schedule regular EBS snapshots with Amazon Data Lifecycle Manager instead of taking them by hand