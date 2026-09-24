provider "aws" {
  region = "us-east-1"
}

#S3 Bucket for Terraform State
resource "aws_s3_bucket" "my_nextjs_bucket" {
  bucket = "my-terraform-state"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name        = "My-TF-State-Bucket"
    Environment = "Dev"
  }
}

#DynamoDB Table for State Locking
resource "aws_dynamodb_table" "my_nextjs_dynamodb" {
  name         = "my-terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "My-TF-State-Lock-Table"
    Environment = "Dev"
  }
}

#Owenership Control for S3 Bucket
resource "aws_s3_bucket_ownership_controls" "my_nextjs_bucket_ownership" {
    bucket = aws_s3_bucket.my_nextjs_bucket.id
    
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
    }

resource "aws_s3_bucket_public_access_block" "my_nextjs_bucket_public_access" {
    bucket = aws_s3_bucket.my_nextjs_bucket.id
    
    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
}

#Bucket ACL
resource "aws_s3_bucket_acl" "my_nextjs_bucket_acl" {

    depends_on = [
      aws_s3_bucket_ownership_controls.my_nextjs_bucket_ownership, 
      aws_s3_bucket_public_access_block.my_nextjs_bucket_public_access
      ]

    bucket = aws_s3_bucket.my_nextjs_bucket.id
    acl    = "public-read"


#bucket policy
resource "aws_s3_bucket_policy" "my_nextjs_bucket_policy" {
    depends_on = [
      aws_s3_bucket_ownership_controls.my_nextjs_bucket_ownership, 
      aws_s3_bucket_public_access_block.my_nextjs_bucket_public_access
      ]

    bucket = aws_s3_bucket.my_nextjs_bucket.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = "*"
                Action = "s3:GetObject"
                Resource = "${aws_s3_bucket.my_nextjs_bucket.arn}/*"
            }
        ]
    })
}