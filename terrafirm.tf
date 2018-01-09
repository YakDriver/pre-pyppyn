provider "aws" {}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_pair_name}"
  public_key = "${var.public_key}"
}

# Security group to access the instances over WinRM
resource "aws_security_group" "terrafirm_winrm" {
  name        = "terrafirm_winrm_sg"
  description = "Used in terrafirm"

  # SSH access from anywhere
  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["${var.cb_ip}/32"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group to access the instances over SSH
resource "aws_security_group" "terrafirm_ssh" {
  name        = "terrafirm_ssh_sg"
  description = "Used in terrafirm"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.cb_ip}/32"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "linux_ami_owners" {
  default = ["701759196663", "self", "125523088429", "099720109477"]
}

variable "windows_ami_owners" {
  default = ["801119661308", "amazon"]
}

variable "ami_filters" {
  default = [
    "spel-minimal-centos-6*",
    "spel-minimal-centos-7*",
  ] 
}

data "aws_ami" "centos6" {
  most_recent = true
  
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name = "name"
    #values = ["spel-minimal-centos-6*"]
    values = ["${lookup(var.ami_filters, 0)}"]
  }
  
  #owners = ["701759196663","self"]
  owners = "${var.linux_ami_owners}"
}

data "aws_ami" "centos7" {
  most_recent = true
  
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name = "name"
    #values = ["spel-minimal-centos-7*"]
    values = ["${lookup(var.ami_filters, 1)}"]
  }
  
  owners = "${var.linux_ami_owners}"
}

data "aws_ami" "rhel6" {
  most_recent = true
  
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name = "name"
    values = ["spel-minimal-rhel-6*"]
  }
  
  owners = "${var.linux_ami_owners}"
}

data "aws_ami" "rhel7" {
  most_recent = true
  
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name = "name"
    values = ["spel-minimal-rhel-7*"]
  }
  
  owners = "${var.linux_ami_owners}"
}

data "aws_ami" "windows2016" {
  most_recent = true
  
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name = "name"
    values = ["Windows_Server-2016-English-Full-Base*"]
  }
  
  owners = "${var.windows_ami_owners}"
}

data "aws_ami" "windows2012" {
  most_recent = true
  
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "name"
    values = ["Windows_Server-2012-R2_RTM-English-64Bit-Base*"]
  }

  owners = "${var.windows_ami_owners}"
}

data "aws_ami" "windows2008" {
  most_recent = true
  
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "name"
    values = ["Windows_Server-2008-R2_SP1-English-64Bit-Base*"]
  }
  
  owners = "${var.windows_ami_owners}"
}

# Data source is used to mitigate lack of intermediate variables and interpolation
data "null_data_source" "spel_instance_amis" {
  inputs = {
    "0" = "${data.aws_ami.centos6.id}"
    "1" = "${data.aws_ami.centos7.id}"
    "2" = "${data.aws_ami.rhel6.id}"
    "3" = "${data.aws_ami.rhel7.id}"
  }
}

resource "aws_instance" "spels" {
  count = "2"
  #count = "${length(data.null_data_source.spel_instance_amis.inputs)}"
  ami = "${lookup(data.null_data_source.spel_instance_amis.inputs, count.index)}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.terrafirm_ssh.id}"]
  user_data = "${file("linux/userdata.sh")}"
  
  timeouts {
    create = "40m"
    delete = "40m"
  }
  
  connection {
    #ssh connection to tier-2 instance
    user     = "${var.ssh_user}"
    private_key = "${var.private_key}"
    timeout   = "30m"
  }
  
  provisioner "remote-exec" {
    script = "linux/watchmaker_test.sh"
  }
}

# Data source is used to mitigate lack of intermediate variables and interpolation
data "null_data_source" "windows_instance_amis" {
  inputs = {
    "0" = "${data.aws_ami.windows2016.id}"
    "1" = "${data.aws_ami.windows2012.id}"
    "2" = "${data.aws_ami.windows2008.id}"
  }
}

resource "aws_instance" "windows" {
  count = "0"
  #count = "${length(data.null_data_source.windows_instance_amis.inputs)}"
  ami = "${lookup(data.null_data_source.windows_instance_amis.inputs, count.index)}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.terrafirm_winrm.id}"]
  user_data = "${file("windows/userdata2.ps1")}"
  
  timeouts {
    create = "40m"
    delete = "40m"
  }
  
  connection {
    #winrm connection to tier-2 instance
    type     = "winrm"
    user     = "${var.term_user}"
    password = "${var.term_passwd}"
    timeout   = "30m"
    #https    = true
  }
  
  provisioner "file" {
    source = "windows/watchmaker_test.ps1"
    destination = "C:\\scripts\\watchmaker_test.ps1"
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }
  
  provisioner "remote-exec" {
    inline = [
      "hostname",
      "powershell.exe -File C:\\scripts\\watchmaker_test.ps1",
    ]
  }
  
}
