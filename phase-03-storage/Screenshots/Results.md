# Phase 3 Results

Paste your saved outputs under each heading. Lines marked **(paste)** need your real output.

## Starting state (Step 3.0)
All `describe-*` checks in us-east-1 returned empty: no instances, volumes, snapshots,
AMIs, Elastic IPs, or EFS file systems.

```text
aws ec2 get-ebs-encryption-by-default
(paste: "EbsEncryptionByDefault": true)
```

## Data volume (Step 3.2)

**Blank volume before formatting:**
```text
(paste: /dev/nvme1n1: data)
```

**Format output:**
```text
(paste the mkfs output: blocks=262144, bsize=4096 = 1 GiB)
```

**Mounted on the web root:**
```text
(paste df -h /var/www/html)
```

**fstab line:**
```text
UUID=<uuid> /var/www/html xfs defaults,nofail 0 2
```

**After reboot:**
```text
$ curl -I localhost/volume.html
HTTP/1.1 200 OK
Server: Apache/2.4.69 (Amazon Linux)
```

## Snapshot restore in us-east-1b (Step 3.3)

**Restored volume before mounting:**
```text
/dev/nvme1n1: SGI XFS filesystem data (blksz 4096, inosz 512, v2 dirs)
```

| Page on mos-web-2 (us-east-1b) | Result |
|---|---|
| `/volume.html` | Loaded |
| `/after.html` | 404 Not Found |
| `/status.html` | Showed us-east-1a (content came from web 1) |

## Golden AMI (Step 3.4)
- AMI `mos-web-golden-v1` created from `mos-web-1` (two backing snapshots)
- Instance launched in us-east-1b with **no user data** served `/volume.html` and
  `/after.html` immediately

## EFS shared storage (Step 3.5)
- File system `mos-shared`, Regional, mount targets in us-east-1a and us-east-1b
- `mos-efs-sg` inbound: NFS 2049 from `mos-staging-sg` only

**Mounted on both servers:**
```text
(paste df -h /var/www/html/shared from mos-web-1)
(paste df -h /var/www/html/shared from the AMI server)
```

- A page written on mos-web-1 appeared at `/shared/` on both servers
- An edit made from the AMI server appeared on both servers

## Teardown (Step 3.6)
```text
(paste the six describe-* outputs: instances terminated, everything else empty)
```