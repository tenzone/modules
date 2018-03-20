terraform {
  backend "s3" {
    bucket = "tfstate-files-tenzer"
    region = "us-east-1"
  }
}
