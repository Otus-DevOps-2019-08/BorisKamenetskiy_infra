terraform {
  backend "gcs" {
    bucket = "storage-bucket-coolbucket123"
    prefix = "terraform/stage"
  }
}

