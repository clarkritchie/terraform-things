resource "aws_kms_key" "kms_key" {
  description = "KMS key for My Company"
}

resource "aws_kms_key_policy" "kms_key_policy" {
  key_id = aws_kms_key.kms_key.id
  policy = jsonencode({
    Id = "mycompany_kms_key"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }

        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
      # allows CloudWatch Alarms to use the key
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }

        Resource = "*"
        Sid      = "Allow CloudWatch Alarms to use the key"
      }
    ]
    Version = "2012-10-17"
  })
}

resource "aws_kms_alias" "kms_key_alias" {
  name          = "alias/mycompany"
  target_key_id = aws_kms_key.kms_key.key_id
}