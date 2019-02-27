# variables.tf – commonly configured parameters for our environment (i.e. projectName)

variable "instCount" {
	default = "1"
}

#################################################
# AWS Region
variable "region" {
	default = "us-east-2"
}
variable "availZoneSuffixes" {
	type = "list"
	default = ["a", "b", "c"]
}

#################################################
# Project naming

variable "projectName" {
	default = "vaultlab"
}
variable "stageName" {
	default = "dev"
}
variable "costCenter" {
	default = "1234.5678"
}

#################################################
# web/app servers

variable "webInstanceType" {
	default = "t2.micro"
}
variable "publicSshKey" {
	default = "./ssh/id_rsa.pub"
}

###############################################################
# Network Vars

variable "vpcCidr" {
	default = "10.0.0.0/16"
}
variable "publicCidr" {
	default = "10.0.0.0/24"
}

###############################################################
# Vault Server

variable "vaultInstanceType" {
	default = "t2.micro"
}

###############################################################
# Database 
variable "dbRootUser" {
	default = "root"
}
variable "dbRootPass" {
	default = "password"
}
variable "dbInstanceCount" {
	default = "1"
}
variable "dbInstanceType" {
	default = "db.t2.micro"
}
variable "dbBackupRetention" {
	default = "0"
}

##############################################################
# Data Lookups
data "aws_ami" "awsLinux2Ami" {
	most_recent = true
	filter {
		name = "owner-alias"
		values = ["amazon"]
	}
	filter {
		name = "name"
		values = ["amzn2-ami-*-x86_64-gp2"]
	}
	filter {
		name = "virtualization-type"
		values = ["hvm"]
	}
}
