packer {
  required_plugins {
    ansible = { version = ">= 1.1.0", source = "github.com/hashicorp/ansible" }
    vagrant = { version = ">= 1.0.3", source = "github.com/hashicorp/vagrant" }
  }
}

source "vagrant" "ubuntu_vm" {
  communicator = "ssh"
  source_path  = "./output-ubuntu_base/package.box"
  provider     = "virtualbox"
  add_force    = true
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_timeout  = "20m"
}

build {
  sources = ["source.vagrant.ubuntu_vm"]

  # Install prerequisites on the Vagrant VM
  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo -E apt-get update",
      "sudo -E apt-get install -y tzdata software-properties-common ansible libopenscap8 wget unzip",
      "sudo bash -c 'if [ ! -d /opt/scap-security-guide-0.1.79 ]; then wget https://github.com/ComplianceAsCode/content/releases/download/v0.1.79/scap-security-guide-0.1.79.zip -O /tmp/ssg.zip && unzip /tmp/ssg.zip -d /opt/ && rm /tmp/ssg.zip; fi'"
    ]
  }

  provisioner "ansible-local" {
    playbook_file           = "./playbook.yml"
    clean_staging_directory = true
  }

  # Download security reports from VM to host
  provisioner "file" {
    direction   = "download"
    source      = "/opt/security_reports/"
    destination = "./Vagrant_Reports/"
  }
}
