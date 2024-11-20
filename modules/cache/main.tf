data "aws_caller_identity" "current" {}

locals {
  tags = merge(
    {
      "Name" = format("%s", var.environment)
    },
    {
      "Environment" = format("%s", var.environment)
    },
    var.tags,
  )

  cache_bucket_name = var.cache_bucket_name_include_account_id ? "${var.cache_bucket_prefix}${data.aws_caller_identity.current.account_id}-gitlab-runner-cache" : "${var.cache_bucket_prefix}-gitlab-runner-cache"
}

resource "aws_s3_bucket" "build_cache" {
  count = var.create_cache_bucket ? 1 : 0

  bucket = local.cache_bucket_name

  tags = local.tags

  force_destroy = true
}

resource "aws_iam_policy" "docker_machine_cache" {
  count = var.create_cache_bucket ? 1 : 0

  name        = "${var.environment}-docker-machine-cache"
  path        = "/"
  description = "Policy for docker machine instance to access cache"

  policy = templatefile("${path.module}/policies/cache.json",
    {
      s3_cache_arn = var.create_cache_bucket == false || length(aws_s3_bucket.build_cache) == 0 ? "${var.arn_format}:s3:::fake_bucket_doesnt_exist" : aws_s3_bucket.build_cache[0].arn
    }
  )
}
