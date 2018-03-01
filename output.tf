output "build_date_ymd" {
  value = "${local.date_ymd}"
}

output "build_date_hm" {
  value = "${local.date_hm}"
}

output "build_id" {
  value = "${local.build_id}"
}

output "amicentos6" {
  value = "${data.aws_ami.centos6.id}"
}

output "amicentos7" {
  value = "${data.aws_ami.centos7.id}"
}

output "amirhel6" {
  value = "${data.aws_ami.rhel6.id}"
}

output "amirhel7" {
  value = "${data.aws_ami.rhel7.id}"
}

output "ami2016" {
  value = "${data.aws_ami.windows2016.id}"
}

output "ami2012" {
  value = "${data.aws_ami.windows2012.id}"
}

output "ami2008" {
  value = "${data.aws_ami.windows2008.id}"
}

output "winrm_pass" {
  value = "${random_string.password.result}"
}

output "private_key" {
  value = "${tls_private_key.gen_key.private_key_pem}"
}

output "public_key" {
  value = "${tls_private_key.gen_key.public_key_openssh}"
}
