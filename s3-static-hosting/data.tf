data "aws_s3_bucket" "bucket" {
  bucket = aws_s3_bucket.bucket.bucket
}

data "aws_iam_policy_document" "bucket-policy" {
  statement {
    sid    = "AllowPublicRead"
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*",
    ]
    actions = ["S3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  depends_on = [aws_s3_bucket_public_access_block.bucket_access_block]
}

