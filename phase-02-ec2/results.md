  (use "git rm --cached <file>..." to unstage)
        new file:   .gitignore/.gitattributes
        new file:   .gitignore/.gitignore
        new file:   Readme.md/Phase 1 Secure AWS Account Baseline.pdf
        new file:   Readme.md/Readme.md
        new file:   phase-01-iam/commands.ps1
        new file:   phase-01-iam/results.md
        new file:   phase-01-iam/s3-readonly-lab.json
        new file:   site/index.html
        new file:   site/server-setup.sh

PS C:\Users\andre\Aws Portfolio> git reset
PS C:\Users\andre\Aws Portfolio> 
 *  History restored 

PS C:\Users\andre\Aws Portfolio> git add .
warning: in the working copy of 'site/index.html', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'site/server-setup.sh', LF will be replaced by CRLF the next time Git touches it
PS C:\Users\andre\Aws Portfolio> git status
On branch master

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
        new file:   .gitattributes
        new file:   .gitignore
        new file:   README.md
        new file:   phase-01-iam/README.md
        new file:   phase-01-iam/commands.ps1
        new file:   phase-01-iam/results.md
        new file:   phase-01-iam/s3-readonly-lab.json
        new file:   site/index.html
        new file:   site/server-setup.sh

PS C:\Users\andre\Aws Portfolio>    git commit -m "Phase 1: IAM and CLI secure account baseline"
Author identity unknown

*** Please tell me who you are.

Run

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

to set your account's default identity.
Omit --global to set the identity only in this repository.

fatal: unable to auto-detect email address (got 'andre@Gamingdesktop.(none)')
PS C:\Users\andre\Aws Portfolio> git config --global user.name "Andrew"
PS C:\Users\andre\Aws Portfolio> git config --global user.email "andrew.mercerkaw@gmai.com"
PS C:\Users\andre\Aws Portfolio> git commit -m "Phase 1: IAM and CLI secure account baseline"
[master (root-commit) 00f8bae] Phase 1: IAM and CLI secure account baseline
 9 files changed, 121 insertions(+)
 create mode 100644 .gitattributes
 create mode 100644 .gitignore
 create mode 100644 README.md
 create mode 100644 phase-01-iam/README.md
 create mode 100644 phase-01-iam/commands.ps1
 create mode 100644 phase-01-iam/results.md
 create mode 100644 phase-01-iam/s3-readonly-lab.json
 create mode 100644 site/index.html
 create mode 100644 site/server-setup.sh
PS C:\Users\andre\Aws Portfolio>  git branch -M main
PS C:\Users\andre\Aws Portfolio>  git remote add origin https://github.com/<your-github-username>/aws-portfolio.git
PS C:\Users\andre\Aws Portfolio>    git push -u origin main
fatal: unable to access 'https://github.com/<your-github-username>/aws-portfolio.git/': The requested URL returned error: 400
PS C:\Users\andre\Aws Portfolio>  git remote add origin https://github.com/andrewmercerkaw-cyber/aws-portfolio.git  
error: remote origin already exists.
PS C:\Users\andre\Aws Portfolio>    git push -u origin main                                                       
fatal: unable to access 'https://github.com/<your-github-username>/aws-portfolio.git/': The requested URL returned error: 400
PS C:\Users\andre\Aws Portfolio>  git branch -M main                                                               
PS C:\Users\andre\Aws Portfolio>  git remote add origin https://github.com/andrewmercerkaw-cyber/aws-portfolio.git
error: remote origin already exists.
PS C:\Users\andre\Aws Portfolio> git remote set-url origin https://github.com/andrewmercerkaw-cyber/aws-portfolio.git
PS C:\Users\andre\Aws Portfolio> git remote -v
origin  https://github.com/andrewmercerkaw-cyber/aws-portfolio.git (fetch)
origin  https://github.com/andrewmercerkaw-cyber/aws-portfolio.git (push)
PS C:\Users\andre\Aws Portfolio> git branch -M main
PS C:\Users\andre\Aws Portfolio> git push -u origin main
info: please complete authentication in your browser...
Enumerating objects: 10, done.
Counting objects: 100% (10/10), done.
Delta compression using up to 12 threads
Compressing objects: 100% (9/9), done.
Writing objects: 100% (10/10), 3.27 KiB | 1.09 MiB/s, done.
Total 10 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To https://github.com/andrewmercerkaw-cyber/aws-portfolio.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
PS C:\Users\andre\Aws Portfolio> git add .
PS C:\Users\andre\Aws Portfolio> git commit -m "Mark Phase 1 complete"
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
PS C:\Users\andre\Aws Portfolio> git push
Everything up-to-date
PS C:\Users\andre\Aws Portfolio>   
 *  History restored 

PS C:\Users\andre\Aws Portfolio> aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,State.Name,Tags[?
>> Key=='Name']|[0].Value]" --output table
PS C:\Users\andre\Aws Portfolio> aws ec2 describe-addresses --output table
--------------------------------------------------------                                                                                                                       
|                   DescribeAddresses                  |
+------------------------------------------------------+
||                      Addresses                     ||
|+---------------------+------------------------------+|
||  AllocationId       |  eipalloc-06b4d44043af511cc  ||
||  Domain             |  vpc                         ||
||  NetworkBorderGroup |  us-east-2                   ||
||  PublicIp           |  3.12.81.117                 ||
||  PublicIpv4Pool     |  amazon                      ||
PS C:\Users\andre\Aws Portfolio> aws ec2 describe-volumes --query "Volumes[].[VolumeId,State,Size]" --output table                                                             
PS C:\Users\andre\Aws Portfolio> aws ec2 release-address --allocation-id eipalloc-06b4d44043af511cc --region us-east-2
PS C:\Users\andre\Aws Portfolio> aws configure set region us-east-1
PS C:\Users\andre\Aws Portfolio> aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,State.Name]" --output table
PS C:\Users\andre\Aws Portfolio> aws ec2 describe-addresses --output table
-------------------                                                                                                                                                            
|DescribeAddresses|
+-----------------+

PS C:\Users\andre\Aws Portfolio> aws ec2 describe-volumes --query "Volumes[].[VolumeId,State,Size]" --output table
PS C:\Users\andre\Aws Portfolio> git config --global user.email "andrew.mercerkaw@gmail.com"
PS C:\Users\andre\Aws Portfolio> ssh -i "$HOME\.ssh\mos-staging-key.pem" ec2-user@<public-ip>
hostname contains invalid characters
PS C:\Users\andre\Aws Portfolio> ssh -i "$HOME\.ssh\mos-staging-key.pem" ec2-user@<http://54.160.237.77/>
hostname contains invalid characters
PS C:\Users\andre\Aws Portfolio> ssh -i "$HOME\.ssh\mos-staging-key.pem" ec2-user@<54.160.237.77>        
hostname contains invalid characters
PS C:\Users\andre\Aws Portfolio> ssh -i "$HOME\.ssh\mos-staging-key.pem" ec2-user@54.160.237.77  
The authenticity of host '54.160.237.77 (54.160.237.77)' can't be established.
ED25519 key fingerprint is SHA256:XkvOROSzWhcfiFEYGjHxtkBEl9PknmjM/jGMHnRa3aw.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '54.160.237.77' (ED25519) to the list of known hosts.
   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___   https://aws.amazon.com/linux/amazon-linux-2023
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'
[ec2-user@ip-172-31-29-155 ~]$ sudo systemctl status httpd
● httpd.service - The Apache HTTP Server
     Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; preset: disabled)
     Active: active (running) since Mon 2026-10-19 17:39:47 UTC; 5min ago
       Docs: man:httpd.service(8)
   Main PID: 4114 (httpd)
     Status: "Total requests: 6; Idle/Busy workers 100/0;Requests/sec: 0.0194; Bytes served/sec:  42 B/sec"
      Tasks: 230 (limit: 1059)
     Memory: 17.5M
        CPU: 381ms
     CGroup: /system.slice/httpd.service
[ec2-user@ip-172-31-29-155 ~]$ sudo tail -20 /var/log/cloud-init-output.log
  git-core-2.50.1-1.amzn2023.0.1.x86_64                                         
  git-core-doc-2.50.1-1.amzn2023.0.1.noarch                                     
  httpd-2.4.69-1.amzn2023.0.2.x86_64                                            
  httpd-core-2.4.69-1.amzn2023.0.2.x86_64                                       
  httpd-filesystem-2.4.69-1.amzn2023.0.2.noarch                                 
  httpd-tools-2.4.69-1.amzn2023.0.2.x86_64                                      
  libbrotli-1.1.0-1.amzn2023.0.1.x86_64                                         
  mailcap-2.1.49-3.amzn2023.0.3.noarch                                          
  mod_http2-1:2.4.69-1.amzn2023.0.2.x86_64                                      
  mod_lua-2.4.69-1.amzn2023.0.2.x86_64                                          
  perl-Error-1:0.17030-2.amzn2023.0.1.noarch                                    
  perl-File-Find-1.37-477.amzn2023.0.10.noarch                                  
  perl-Git-2.50.1-1.amzn2023.0.1.noarch                                         
  perl-TermReadKey-2.38-9.amzn2023.0.3.x86_64                                   
  perl-lib-0.65-477.amzn2023.0.10.x86_64                                        

Complete!
Created symlink /etc/systemd/system/multi-user.target.wants/httpd.service → /usr/lib/systemd/system/httpd.service.
Cloning into '/tmp/repo'...
Cloud-init v. 22.2.2 finished at Mon, 19 Oct 2026 17:39:47 +0000. Datasource DataSourceEc2.  Up 38.43 seconds
[ec2-user@ip-172-31-29-155 ~]$ aws sts get-caller-identity --region us-east-1
{
    "UserId": "AROA5T7SRKEBM6CHUZRQA:i-00fe20e34e663569a",
    "Account": "936274645250",
    "Arn": "arn:aws:sts::936274645250:assumed-role/mos-staging-ec2-role/i-00fe20e34e663569a"
}
[ec2-user@ip-172-31-29-155 ~]$ aws s3 ls --region us-east-1
[ec2-user@ip-172-31-29-155 ~]$ aws iam list-users --region us-east-1

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListUsers operation: User: arn:aws:sts::936274645250:assumed-role/mos-staging-ec2-role/i-00fe20e34e663569a is not authorized to perform: iam:ListUsers on resource: arn:aws:iam::936274645250:user/ because no identity-based policy allows the iam:ListUsers action
[ec2-user@ip-172-31-29-155 ~]$ ls ~/.aws
cli
[ec2-user@ip-172-31-29-155 ~]$   ls ~/.aws/credentials
ls: cannot access '/home/ec2-user/.aws/credentials': No such file or directory
[ec2-user@ip-172-31-29-155 ~]$ Connection to 54.160.237.77 closed by remote host.
Connection to 54.160.237.77 closed.
PS C:\Users\andre\Aws Portfolio> aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,State.Name]" --output table
>> aws ec2 describe-addresses --output table
>> aws ec2 describe-volumes --query "Volumes[].[VolumeId,State]" --output table
---------------------------------------                                                                                                                                        
|          DescribeInstances          |
+----------------------+--------------+
|  i-00fe20e34e663569a |  terminated  |
+----------------------+--------------+

-------------------                                                                                                                                                            
|DescribeAddresses|
+-----------------+

PS C:\Users\andre\Aws Portfolio> 