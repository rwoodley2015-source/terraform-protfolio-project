terraform {
  backend "s3" {
    bucket = "rwnextjs-portfolio-rob-blog"
    key    = "terraform.tfstate"
    region = "us-east-1"
    # dynamodb_table = "nextjs-portfolio-rob-blog-lock"
    use_lockfile = true
  }
}
