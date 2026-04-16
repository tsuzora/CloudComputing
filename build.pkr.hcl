packer {
  required_plugins {
    docker  = { version = ">= 1.0.8", source = "github.com/hashicorp/docker" }
    ansible = { version = ">= 1.1.0", source = "github.com/hashicorp/ansible" }
    vagrant = { version = ">= 1.0.3", source = "github.com/hashicorp/vagrant" }
  }
}

source "docker" "ubuntu" {
  image  = "ubuntu:22.04"
  commit = true
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
  sources = [
    "source.docker.ubuntu",
    "source.vagrant.ubuntu_vm"
  ]

  # Docker
  provisioner "shell" {
    only = ["docker.ubuntu"]
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      # Run natively as root without sudo
      "apt-get update",
      # MUST install 'sudo' here so Ansible's 'become: yes' doesn't crash later
      "apt-get install -y sudo tzdata software-properties-common ansible libopenscap8 wget unzip",
      "bash -c 'if [ ! -d /opt/scap-security-guide-0.1.79 ]; then wget https://github.com/ComplianceAsCode/content/releases/download/v0.1.79/scap-security-guide-0.1.79.zip -O /tmp/ssg.zip && unzip /tmp/ssg.zip -d /opt/ && rm /tmp/ssg.zip; fi'"
    ]
  }

  #Vagrant
  provisioner "shell" {
    only = ["vagrant.ubuntu_vm"]
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      # Must use sudo to elevate privileges
      "sudo -E apt-get update",
      "sudo -E apt-get install -y tzdata software-properties-common ansible libopenscap8 wget unzip",
      "sudo bash -c 'if [ ! -d /opt/scap-security-guide-0.1.79 ]; then wget https://github.com/ComplianceAsCode/content/releases/download/v0.1.79/scap-security-guide-0.1.79.zip -O /tmp/ssg.zip && unzip /tmp/ssg.zip -d /opt/ && rm /tmp/ssg.zip; fi'"
    ]
  }

  provisioner "ansible-local" {
    playbook_file           = "./playbook.yml"
    clean_staging_directory = true
  }

provisioner "file" {
    only        = ["docker.ubuntu"]
    direction   = "download"
    source      = "/opt/security_reports/baseline_report.html"
    destination = "./docker_baseline_report.html"
  }

  provisioner "file" {
    only        = ["docker.ubuntu"]
    direction   = "download"
    source      = "/opt/security_reports/post_hardening_report.html"
    destination = "./docker_post_hardening_report.html"
  }

  # Vagrant supports directory downloads natively, so we leave it alone
  provisioner "file" {
    only        = ["vagrant.ubuntu_vm"]
    direction   = "download"
    source      = "/opt/security_reports/"
    destination = "./Vagrant_Reports/"
  }
}