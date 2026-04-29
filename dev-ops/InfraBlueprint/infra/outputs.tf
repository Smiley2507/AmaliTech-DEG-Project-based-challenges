output "ec2_public_ip" {
  description = "Public IP address of the Vela web server. Use this to SSH in or point a DNS record at."
  value       = aws_instance.web.public_ip
}

output "rds_endpoint" {
  description = "Connection endpoint for the RDS PostgreSQL instance. Use this in your application's database config."
  value       = aws_db_instance.main.endpoint
}

output "s3_bucket_name" {
  description = "Name of the S3 static assets bucket."
  value       = aws_s3_bucket.assets.bucket
}

output "vpc_id" {
  description = "ID of the Vela VPC. Useful for adding future resources to the same network."
  value       = aws_vpc.main.id
}