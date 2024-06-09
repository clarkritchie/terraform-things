resource "aws_s3_object" "file" {
  for_each = var.create_s3_objects ? fileset(path.module, "src/**/*.{html,css,js}") : []

  bucket       = aws_s3_bucket.bucket.id
  key          = replace(each.value, "/^src//", "")
  source       = each.value
  content_type = lookup(local.content_types, regex("\\.[^.]+$", each.value), null)
  source_hash  = filemd5(each.value)
}