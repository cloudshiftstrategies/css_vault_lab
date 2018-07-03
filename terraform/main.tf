# main.tf – tells terraform which provider to use (AWS)

provider "aws" {
  region = "${var.region}"
}
