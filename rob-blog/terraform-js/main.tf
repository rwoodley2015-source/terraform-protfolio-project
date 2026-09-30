provider "aws" {
  region = "us-east-1"
}

#S3 bucket for storing the state file
resource "aws_s3_bucket" "terraform_state" {
  bucket = "rwnextjs-portfolio-rob-blog"
}

#S3 Ownership controls to prevent accidental deletion of the state file
resource "aws_s3_bucket_ownership_controls" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#Public access block settings for the bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

#Bucket ACL
resource "aws_s3_bucket_acl" "terraform_state" {
  depends_on = [
    aws_s3_bucket_ownership_controls.terraform_state,
    aws_s3_bucket_public_access_block.terraform_state
  ]

  bucket = aws_s3_bucket.terraform_state.id
  acl    = "public-read"
}

#Bucket Policy
resource "aws_s3_bucket_policy" "terraform_state" {
  depends_on = [
    aws_s3_bucket_acl.terraform_state
  ]

  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      }
    ]
  })
}


#Origin Access Identity for CloudFront
resource "aws_cloudfront_origin_access_identity" "s3_oai" {
  comment = "OAI for nextjs-portfolio-rob-blog"
}

#CloudFront Distribution for the S3 bucket
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.terraform_state.bucket_regional_domain_name
    origin_id   = "S3-nextjs-portfolio-rob-blog"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for nextjs-portfolio-rob-blog"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-nextjs-portfolio-rob-blog"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}