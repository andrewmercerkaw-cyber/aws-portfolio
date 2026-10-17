aws: [ERROR]: An error occurred (AccessDenied) when calling the ListUsers operation: User: arn:aws:iam::936274645250:user/test-readonly is not authorized to perform: iam:ListUsers on resource: arn:aws:iam::936274645250:user/ because no identity-based policy allows the iam:ListUsers action
PS C:\Users\andre\Aws Portfolio\phase-01-iam> aws s3 mb s3://andrew-lab-test-bucket-12345 --profile test
make_bucket failed: s3://andrew-lab-test-bucket-12345 An error occurred (AccessDenied) when calling the CreateBucket operation: User: arn:aws:iam::936274645250:user/test-readonly is not authorized to perform: s3:CreateBucket on resource: "arn:aws:s3:::andrew-lab-test-bucket-12345" because no identity-based policy allows the s3:CreateBucket action
PS C:\Users\andre\Aws Portfolio\phase-01-iam>
PS C:\Users\andre\Aws Portfolio\phase-01-iam>   aws iam detach-user-policy --user-name test-readonly --policy-arn arn:aws:iam::936274645250:policy/S3ReadOnlyLab
PS C:\Users\andre\Aws Portfolio\phase-01-iam> aws iam delete-user --user-name test-readonly
PS C:\Users\andre\Aws Portfolio\phase-01-iam> aws iam get-user --user-name test-readonly

aws: [ERROR]: An error occurred (NoSuchEntity) when calling the GetUser operation: The user with name test-readonly cannot be found.
PS C:\Users\andre\Aws Portfolio\phase-01-iam>
## Credential report check (2026-10-17)
- Root: MFA on, no access keys
- Andrew: MFA added after report review; CLI access key active (expected)
- test-readonly: not present (cleanup verified)