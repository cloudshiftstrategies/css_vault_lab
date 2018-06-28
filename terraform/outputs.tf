# output.tf - outputs important parameters will need to finish configuring vault
# These parameters will but spit out after each terraform apply

output "KEYFILE" {
	value = "${var.publicSshKey}"
}

output "VAULT_IP" {
	value = "${aws_instance.vault.*.private_ip}"
}

output "MYSQL_HOST" {
	value = "${aws_rds_cluster.rds_cluster.endpoint}"
}

output "MYSQL_USER" {
	value = "${aws_rds_cluster.rds_cluster.master_username}"
}

output "MYSQL_PASS" {
	value = "${aws_rds_cluster.rds_cluster.master_password}"
}

output "MYSQL_DB" {
	value = "${aws_rds_cluster.rds_cluster.database_name}"
}

output "MYSQL_PORT" {
	value = "${aws_rds_cluster.rds_cluster.port}"
}

output "WEB_PROFILE_ARN" {
	value = "${aws_iam_instance_profile.web_profile.arn}"
}
