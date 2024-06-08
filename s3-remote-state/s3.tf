resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.remote-state-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket" "remote-state-bucket" {
    bucket = "terraform-state-clarkritchie"
    object_lock_enabled = true
    tags = {
        Name = "S3 remote state for Terraform"
    }
}