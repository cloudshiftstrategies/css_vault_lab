# network.tf – creates VPC, public subnet, route table & internet gateway

###############################################################
# VPC

# Create a new VPC for this project
resource "aws_vpc" "vpc" {
	cidr_block = "${var.vpcCidr}"
	enable_dns_hostnames = true
	tags {
		Name    = "${var.projectName}-${var.stageName}-vpc",
		Project = "${var.projectName}",
		Stage   = "${var.stageName}"
		CostCenter = "${var.costCenter}"
	}
}

# Create an Internet Gateway for the public subnet
resource "aws_internet_gateway" "igw" {
	vpc_id = "${aws_vpc.vpc.id}"
	tags {
		Name    = "${var.projectName}-${var.stageName}-igw",
		Project = "${var.projectName}",
		Stage   = "${var.stageName}"
		CostCenter = "${var.costCenter}"
	}
}

###############################################################
# Public Subnet

# Create one public subnet
resource "aws_subnet" "public_subnet" {
	vpc_id  = "${aws_vpc.vpc.id}"
	cidr_block = "${var.publicCidr}"
	availability_zone = "${var.region}${var.availZoneSuffixes[0]}"
	map_public_ip_on_launch = true
	tags {
		Name = "${var.projectName}-${var.stageName}-${var.region}${var.availZoneSuffixes[0]}-public-sn"
		Project = "${var.projectName}",
		Stage   = "${var.stageName}"
		CostCenter = "${var.costCenter}"
  }
}

# Create a singe route table for public subnet
resource "aws_route_table" "publicRouteTable" {
	vpc_id = "${aws_vpc.vpc.id}"
	tags {
		Name = "${var.projectName}-${var.stageName}-public-routeTable"
		Project = "${var.projectName}",
		Stage   = "${var.stageName}"
		CostCenter = "${var.costCenter}"
	}
}

# Add a rule to the public route table, making the Internet GW the default route
resource "aws_route" "publicIgwRoute" {
  route_table_id         = "${aws_route_table.publicRouteTable.id}"
  gateway_id             = "${aws_internet_gateway.igw.id}"
  destination_cidr_block = "0.0.0.0/0"
}

# Associate public Subnet with the igw Route Table
resource "aws_route_table_association" "publicRteTblAssoc" {
	subnet_id      = "${aws_subnet.public_subnet.id}"
	route_table_id = "${aws_route_table.publicRouteTable.id}"
}
