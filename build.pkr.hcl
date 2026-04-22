packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "docker" "ubuntu" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  sources = ["source.docker.ubuntu"]

  # DOCKER PREPARATION (Runs as Root)
provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      "apt-get install -y sudo tzdata software-properties-common ansible libopenscap8 wget unzip",
      # Added retry logic to the wget command to prevent pipeline crashes on transient connection drops
      "bash -c 'if [ ! -d /opt/scap-security-guide-0.1.79 ]; then wget --tries=5 --retry-connrefused --waitretry=2 https://github.com/ComplianceAsCode/content/releases/download/v0.1.79/scap-security-guide-0.1.79.zip -O /tmp/ssg.zip && unzip /tmp/ssg.zip -d /opt/ && rm /tmp/ssg.zip; fi'"
    ]
  }

  provisioner "ansible-local" {
    playbook_file           = "./playbook.yml"
    clean_staging_directory = true 
  }

  # AUTOMATED REPORT EXTRACTION
  provisioner "file" {
    direction   = "download"
    source      = "/opt/security_reports/docker_cis_baseline.html"
    destination = "./docker_cis_baseline.html"
  }

  provisioner "file" {
    direction   = "download"
    source      = "/opt/security_reports/docker_cis_hardened.html"
    destination = "./docker_cis_hardened.html"
  }
}