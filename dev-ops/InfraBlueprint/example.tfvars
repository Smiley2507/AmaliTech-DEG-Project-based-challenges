# Copy this file to infra/staging.tfvars or infra/production.tfvars
# and fill in real values. Never commit files with real credentials.

aws_region       = "eu-north-1"
vpc_cidr         = "10.0.0.0/16"
allowed_ssh_cidr = "YOUR_IP/32"        # Run: curl https://checkip.amazonaws.com
db_username      = "velaadmin"          # Choose a strong username
db_password      = "REPLACE_ME"        # Minimum 8 characters
s3_bucket_name   = "vela-assets-YOUR_UNIQUE_SUFFIX"
ec2_ami          = "ami-0a0823e4ea064404d"  # Amazon Linux 2023, eu-north-1
environment      = "staging"