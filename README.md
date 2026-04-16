# **DevSecOps IaC Research Pipeline: VM vs. Container Security**

## **What This Program Is For**

This project is an automated Infrastructure as Code (IaC) DevSecOps pipeline designed for academic research. It generates empirical data to compare how security hardening (specifically CIS Benchmarks) is applied and measured across two distinct computing architectures:

1. **IaaS (Virtual Machines):** Represented by VirtualBox & Vagrant (bento/ubuntu-22.04).  
2. **CaaS (Containers):** Represented by Docker (ubuntu:22.04).

The system uses **Packer** to orchestrate the infrastructure, **Ansible** to enforce security configurations, and **OpenSCAP** to perform automated vulnerability scans. The core objective is to demonstrate that while unified automation tools (Ansible) can provision both architectures, the security paradigms, necessary configurations, and benchmark tooling required for each are fundamentally different.

## **The Pipeline Architecture (Flowchart Implementation)**

The execution of this repository is a direct technical implementation of the experimental workflow flowchart. The entire 3-step process runs in parallel for both the Vagrant VM and the Docker container.

### **Step 1: Baseline Scan**

Before any security configurations are applied, Ansible triggers OpenSCAP (oscap xccdf eval) against the raw Ubuntu 22.04 environments using the standard SSG (SCAP Security Guide) profile. This generates the baseline\_report.html, capturing the default state of the OS prior to intervention.

### **Step 2: Ansible Hardening**

Ansible executes playbook.yml. This stage contains conditional security logic. It uses Ansible facts (ansible\_virtualization\_type) to detect whether the target environment is a hypervisor or a container engine. It applies relevant security configurations (e.g., disabling SSH root login) to the VM while bypassing those tasks in the container where they do not logically apply.

### **Step 3: Post-Hardening Scan**

Immediately after the playbook finishes, Ansible triggers a second OpenSCAP scan. This generates the post\_hardening\_report.html. Packer then securely downloads all four HTML reports (two for Vagrant, two for Docker) directly to the Windows host machine for analysis, and subsequently destroys the temporary environments.

## **Fresh Start Setup Guide**

### **1\. Prerequisites (Windows Host)**

This pipeline is strictly engineered to run natively on a Windows host to avoid nested-virtualization kernel panics. Do not run this inside WSL. Ensure the following are installed and added to your System PATH:

* [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/) (Must be running in the system tray).  
* [Oracle VirtualBox](https://www.virtualbox.org/wiki/Downloads)  
* [HashiCorp Vagrant](https://developer.hashicorp.com/vagrant/downloads)  
* [HashiCorp Packer](https://developer.hashicorp.com/packer/downloads)

### **2\. Repository Initialization**

Open **Windows PowerShell**, clone this repository to your local machine, and initialize the Packer plugins:

git clone \<your-github-repo-url\>  
cd \<your-repository-folder\>  
packer init base.pkr.hcl  
packer init build.pkr.hcl

### **3\. Stage 1: Build the Base Image (Run Once)**

Before running rapid tests, you must compile the cached base image. This step bootstraps the Vagrant VM, downloads the OpenSCAP binaries and zip files, and packages them. This takes roughly 10-15 minutes but only needs to be executed once.

packer build base.pkr.hcl

*Output:* A local file named package.box is generated inside the ./output-ubuntu\_base/ directory.

### **4\. Stage 2: Execute the Research Pipeline (Rapid Testing)**

Run the main testing pipeline. This command uses the \-force flag to automatically overwrite previous test artifacts, enabling continuous iteration.

packer build \-force build.pkr.hcl

*Execution Flow:* VirtualBox will briefly open a monitor window, Docker will spin up in the background, and Ansible will execute the 3-step flowchart. The entire run will complete in 2-4 minutes.

## **Analyzing the Results & Negative Data Points**

Once the build completes, the following files will extract to your project root:

* Vagrant\_Reports/baseline\_report.html  
* Vagrant\_Reports/post\_hardening\_report.html  
* docker\_baseline\_report.html  
* docker\_post\_hardening\_report.html

**Documented Negative Results:**

* **Docker "Not Applicable" Flags:** The Docker OpenSCAP reports will return hundreds of notapplicable rules. OpenSCAP is scanning for OS-level parameters (kernel modules, bootloaders, disk partitions) that physically do not exist inside a container's shared-kernel architecture.  
* **Identical Vagrant Scores:** The baseline and post-hardening scores for the Vagrant VM will be identical if the playbook only contains the SSH root login restriction. The bento base box disables this by default, meaning Ansible reports changed=0 and the OS state remains exactly the same between Step 1 and Step 3\.

### **Are you sure?**

Are you sure the OpenSCAP scanner is functioning correctly if it returns hundreds of notapplicable results for Docker instead of standard failures? Yes. The OpenSCAP scanner (oscap) natively detects container virtualization contexts. It is explicitly programmed to bypass rules labeled with the machine or os context when executing inside a container, preventing the generation of false-positive failures for subsystems it cannot access.

## **Cleanup & Maintenance**

Rapidly building containers will bloat your host drive with dangling (overwritten) images. Run this command frequently to wipe out ghost images from previous test runs:

docker image prune \-f

To perform a complete wipe of the Docker cache (Note: this forces a re-download of the base ubuntu:22.04 image on the next run):

docker system prune \-a \-f

## **References & Credible Sources**

* **Red Hat Documentation (Journals/Technicals):** [Vulnerability scanning of containers with OpenSCAP](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/managing_containers/vulnerability_scanning_with_openscap)  
* **StackOverflow (Coding/Technicals):** [Ansible 'ok' vs 'changed' status](https://stackoverflow.com/questions/44122143/ansible-ok-vs-changed-status)  
* **Center for Internet Security (Journals):** [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
