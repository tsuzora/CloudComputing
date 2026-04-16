packer {
  required_plugins {
    vagrant = {
      version = ">= 1.0.3"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

# Source: The standard cloud Ubuntu image
source "vagrant" "ubuntu_base" {
  communicator = "ssh"
  source_path  = "bento/ubuntu-22.04"
  provider     = "virtualbox"
  add_force    = true

  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_timeout  = "20m"

  # Tell Packer to use your custom Vagrantfile template
  template = "vagrantfile.tpl"

}

build {
  sources = ["source.vagrant.ubuntu_base"]

  # Provisioner: Install all prerequisites. NO hardening happens here.
  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo -E apt-get update",

      # 1. Install Ansible and dependencies
      "sudo -E apt-get install -y tzdata software-properties-common ansible",

      # 2. Install OpenSCAP and download the Security Guide
      "sudo -E apt-get install -y libopenscap8 wget unzip",
      "sudo wget https://github.com/ComplianceAsCode/content/releases/download/v0.1.79/scap-security-guide-0.1.79.zip -O /tmp/ssg.zip",
      "sudo unzip /tmp/ssg.zip -d /opt/",
      "sudo rm /tmp/ssg.zip"
    ]
  }
}