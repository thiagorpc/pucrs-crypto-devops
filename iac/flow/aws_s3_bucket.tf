# ============================
# File: ./iac/flow/aws_s3_bucket.tf
# ============================

# ============================
# S3 para Frontend React (UI)
# ============================
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend"
  tags   = { Name = "${var.project_name}-ui-bucket" }

  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "ui_ownership" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


