{{ .DefaultTemplate }}

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
  end

  config.vm.network "forwarded_port", guest: 22, host: 2229, id: "ssh", auto_correct: false

  # Force power-off instead of graceful halt (fixes halt timeout on Windows)
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--acpi", "on"]
  end
end