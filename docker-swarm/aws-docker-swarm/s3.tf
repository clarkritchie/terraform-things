# terraform plan -target aws_s3_bucket.config_bucket -var-file chaos.tfvars
resource "aws_s3_bucket" "config_bucket" {
  bucket = "docker-swarm-${var.environment}"
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "config_bucket_versioning" {
  bucket = aws_s3_bucket.config_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# upload the actual user data script to the s3 bucket
# manual upload: aws s3 cp user_data.sh s3://docker-swarm-chaos/
resource "aws_s3_object" "user_data" {
  bucket = aws_s3_bucket.config_bucket.bucket
  key    = "user_data.sh"
  source = "${path.module}/etc/user_data.sh"
  tags   = local.tags
}
# terraform plan -target aws_s3_bucket.authorized_keys -var-file env-dev.tfvars
resource "aws_s3_object" "authorized_keys" {
  bucket = aws_s3_bucket.config_bucket.bucket
  key    = "authorized_keys"
  source = "${path.module}/etc/authorized_keys"
  tags   = local.tags
}

# upload the actual run script to the s3 bucket
# manual upload: aws s3 cp run_swarm.sh s3://docker-swarm-chaos/run.sh
resource "aws_s3_object" "run_script" {
  bucket = aws_s3_bucket.config_bucket.bucket
  key    = "run.sh"
  source = "${path.module}/etc/run_swarm.sh"
  tags   = local.tags
}

# upload the sync script to the bucket
# manual upload: aws s3 cp sync.sh s3://docker-swarm-dev/sync.sh
resource "aws_s3_object" "sync_script" {
  bucket = aws_s3_bucket.config_bucket.bucket
  key    = "sync.sh"
  source = "${path.module}/etc/sync.sh"
  tags   = local.tags
}

# upload the bashrc to the bucket
# manual upload: aws s3 cp bashrc s3://docker-swarm-chaos/bashrc
resource "aws_s3_object" "bashrc" {
  bucket = aws_s3_bucket.config_bucket.bucket
  key    = "bashrc"
  source = "${path.module}/etc/bashrc"
  tags   = local.tags
}