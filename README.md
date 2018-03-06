# Pyppyn
Pyppyn builds (or hopefully someday will) Python packages for Windows and Linux to install [Watchmaker](https://github.com/plus3it/watchmaker).

This project uses [Terraform](https://github.com/hashicorp/terraform) and can work with [AWS CodeBuild](https://aws.amazon.com/codebuild/). You can control some aspects with environment variables.

## ENVIRONMENT VARIABLES EXPECTED BY Pyppyn

Variable | Default | Req/Opt (in CodeBuild) | Description
--- | --- | --- | ---
`TF_VAR_tfi_subnet_id` | [empty] | optional | Whether or not to use a subnet. CodeBuild instance must be able to access.
`TF_VAR_tfi_win_instances` | [empty] | optional | Acceptable values are "win08", "win12", and/or "win16" (comma separated list). If none are wanted, remove variable from CodeBuild.
`TF_VAR_tfi_lx_instances` | [empty] | optional | Acceptable values are "centos6", "centos7", "rhel6" and/or "rhel7" (comma separated list). If none are wanted, remove variable from CodeBuild.
`TF_VAR_tfi_rm_user` | Administrator | optional | username to use when connecting via WinRM to Windows instances
`TF_VAR_tfi_ssh_user` | root | optional | Which username to use when connecting via SSH to Linux instances.
`TF_VAR_tfi_instance_profile` | [empty] | optional | Instance profile to be used in provisioning resources. This is generally the same as the role if the role is an EC2 role.
`TF_VAR_tfi_assign_public_ip` | false | optional | Whether or not to assign a public IP to the instances built by Terraform.
`TF_VAR_tfi_win_instance_type` | t2.medium | optional | AWS instance type for Windows instances.
`TF_VAR_tfi_lx_instance_type` | t2.micro | optional | AWS instance type for Linux instances.
`TF_VAR_tfi_git_repo` | https://github.com/plus3it/watchmaker.git | optional | Which git repository to use in getting watchmaker code.
`TF_VAR_tfi_git_ref` | master | optional | Which branch or pull request number of the repository to use in getting watchmaker code.
`TF_VAR_tfi_common_args` | -n --log-level debug | optional | Command line arguments used when installing Watchmaker (Windows/Linux).
`TF_VAR_tfi_win_args` | --log-dir=C:\\Watchmaker\\Logs | optional | Command line arguments used when installing Watchmaker (Windows).
`TF_VAR_tfi_lx_args` | --log-dir=/var/log/watchmaker | optional | Command line arguments used when installing Watchmaker (Linux).
`TF_VAR_tfi_s3_bucket` | mybucket | optional | Which S3 bucket to place logs from installs and output from Terraform.
`TFI_DESTROY_AFTER_TEST` | true | optional | Whether or not to destroy all resources created after the test. (WARNING: Depending on failure, Terraform may not always be able to destroy provisioned resources.)

