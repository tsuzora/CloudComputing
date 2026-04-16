{{ .DefaultTemplate }}

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
  end
  
  # Force Vagrant to use port 2229 for SSH and prevent it from auto-guessing
  config.vm.network "forwarded_port", guest: 22, host: 2229, id: "ssh", auto_correct: false
end