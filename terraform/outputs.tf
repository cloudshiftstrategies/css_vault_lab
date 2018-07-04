# output.tf - outputs important parameters will need to finish configuring vault
# These parameters will but spit out after each terraform apply

output "VAULT_PUBLIC_IPS" {
	value = "${aws_instance.vault.*.public_ip}"
}
output "WEB_PUBLIC_IPS" {
	value = "${aws_instance.webInst.*.public_ip}"
}
output "VAULT_PRIVATE_IPS" {
	value = "${aws_instance.vault.*.private_ip}"
}
output "WEB_PRIVATE_IPS" {
	value = "${aws_instance.webInst.*.private_ip}"
}
output "WEB_PROFILE_ARN" {
	value = "${aws_iam_instance_profile.web_profile.arn}"
}
