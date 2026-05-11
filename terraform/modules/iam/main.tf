locals {
  tags = merge(var.tags, {
    Name = var.role_name
  })
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.trusted_service]
    }
  }
}

resource "aws_iam_role" "gateway" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = local.tags
}

data "aws_iam_policy_document" "artifact_upload" {
  statement {
    sid     = "PutValidatedArtifacts"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    resources = [
      "${var.artifacts_bucket_arn}/${var.artifacts_prefix}*",
    ]
  }

  statement {
    sid     = "ListValidatedPrefix"
    effect  = "Allow"
    actions = ["s3:ListBucket"]

    resources = [var.artifacts_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.artifacts_prefix}*"]
    }
  }
}

resource "aws_iam_policy" "artifact_upload" {
  name        = "${var.role_name}-artifact-upload"
  description = "Allows the Gateway to upload validated artifacts to the designated S3 prefix"
  policy      = data.aws_iam_policy_document.artifact_upload.json

  tags = merge(local.tags, {
    Name = "${var.role_name}-artifact-upload"
  })
}

resource "aws_iam_role_policy_attachment" "artifact_upload" {
  role       = aws_iam_role.gateway.name
  policy_arn = aws_iam_policy.artifact_upload.arn
}

resource "aws_iam_instance_profile" "gateway" {
  name = var.role_name
  role = aws_iam_role.gateway.name

  tags = local.tags
}
