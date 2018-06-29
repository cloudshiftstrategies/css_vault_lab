# web.tf – builds load balancer, auto scaling groups, launch configs & web security groups

###########################################################
# Web Instance
resource "aws_instance" "webInst" {
  count = "${var.instCount}"
  ami = "${data.aws_ami.awsLinux2Ami.id}"
  instance_type = "${var.webInstanceType}"
  subnet_id = "${aws_subnet.public_subnet.id}"
  iam_instance_profile = "${aws_iam_instance_profile.web_profile.id}"
  user_data = "${element(data.template_file.webuserdata.*.rendered, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.web_sg.id}"]
  key_name = "${aws_key_pair.public_key.key_name}"
  tags {
    Name = "${count.index}-web-${var.projectName}-${var.stageName}-inst"
    VaultIP = "${element(aws_instance.vault.*.private_ip, count.index)}"
  }
}

###########################################################
# Web Instance IAM role

# Create an IAM role we can attach to an EC2 instance
resource "aws_iam_role" "web_role" {
    name = "${var.projectName}-${var.stageName}-webinst-role"
	description = "Role that allows EC2 instance to write to cloudwatch logs and read tags"
	assume_role_policy = <<EOF
{
	"Version":"2012-10-17",
	"Statement":[
		{
			"Sid":"",
			"Effect":"Allow",
			"Principal":{"Service":"ec2.amazonaws.com"},
			"Action":"sts:AssumeRole"
		}
	]
}
EOF
}

# Attach a policy to the web role that allows instance to read ec2 tags
resource "aws_iam_role_policy" "web_policy" {
    name = "${var.projectName}-${var.stageName}-webinst-policy"
	role = "${aws_iam_role.web_role.id}"
	policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
		"Effect": "Allow",
		"Action": [
			"ec2:DescribeTags",
			"ec2:DescribeInstances"
		],
		"Resource": ["*"]
	}
 ]
}
EOF
}

# Create an IAM instance profile that allows us to attach IAM role to EC2 instance
resource "aws_iam_instance_profile" "web_profile" {
    name = "${var.projectName}-${var.stageName}-web-profile"
	role = "${aws_iam_role.web_role.name}"
}

###########################################################
# Security Group

# Security Group that allows ssh access from internet
resource "aws_security_group" "web_sg" {
	name = "${var.projectName}-${var.stageName}-web-sg"
	vpc_id = "${aws_vpc.vpc.id}"
	tags {
		Name = "${var.projectName}-${var.stageName}-web-sg"
	}
}

# Rule to allow web servers to talk via port 0080 to public (load balancer) subnet only
resource "aws_security_group_rule" "web_sg_22in" {
	type            = "ingress"
	from_port       = 22
	to_port         = 22
	protocol        = "tcp"
	cidr_blocks		= ["0.0.0.0/0"]
	security_group_id = "${aws_security_group.web_sg.id}"
}

# Rule to allow web servers to talk via port 0080 to public (load balancer) subnet only
resource "aws_security_group_rule" "web_sg_8000in" {
	type            = "ingress"
	from_port       = 8000 
	to_port         = 8000
	protocol        = "tcp"
	cidr_blocks		= ["0.0.0.0/0"]
	security_group_id = "${aws_security_group.web_sg.id}"
}

# Rule to allow web servers to talk out to the world
resource "aws_security_group_rule" "web_sg_ALLout" {
	type            = "egress"
	from_port       = 0 
	to_port         = 0
	protocol        = "-1"
	cidr_blocks		= ["0.0.0.0/0"]
	security_group_id = "${aws_security_group.web_sg.id}"
}

data "template_file" "webuserdata" {
  count = "${var.instCount}"
  template = "${file("./webuserdata.sh")}"
  vars {
    VAULT_IP = "${element(aws_instance.vault.*.private_ip, count.index)}"
  }
}
