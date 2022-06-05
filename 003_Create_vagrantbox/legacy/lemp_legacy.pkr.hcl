source "virtualbox-iso" "ubu_lamp" {

  # See all types - "VBoxManage list ostypes | grep ubuntu"
  guest_os_type = "Ubuntu_64"

  iso_url = "http://cdimage.ubuntu.com/ubuntu-legacy-server/releases/focal/release/ubuntu-20.04.1-legacy-server-amd64.iso"
  iso_checksum = "sha256:f11bda2f2caed8f420802b59f382c25160b114ccc665dbac9c5046e7fceaced2"

  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_port = "22"
  ssh_wait_timeout = "30m"

  guest_additions_path = "VBoxGuestAdditions_{{.Version}}.iso"
  virtualbox_version_file = ".vbox_version"

  shutdown_command = "echo \"vagrant\" | sudo -S systemctl poweroff"
  shutdown_timeout = "1m"

  firmware = "bios"
  disk_size = "12000"
  hard_drive_interface = "sata"
  nic_type = "82543GC"

  vm_name = "ubu-lamp"

  cpus = "6"
  memory = "4096"
  sound = "none"
  usb = false

  boot_wait = "5s"
  headless = false

  http_directory = "./http"
  boot_command = [
    "<esc><wait1s>",
    "<esc><wait1s>",
    "<enter><wait1s>",
    "/install/vmlinuz",
    " initrd=/install/initrd.gz",
    " auto-install/enable=true",
    " debconf/priority=critical",
    " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
    " netcfg/get_hostname=ubu-lamp<wait1s>",
    " -- <wait1s>",
    "<enter><wait1s>"
  ]

}

build {

  sources = ["sources.virtualbox-iso.ubu_lamp"]

  provisioner "file" {
    pause_before = "5s"
    source = "./keys/vagrant.pub"
    destination = "/tmp/authorized_keys"
  }

  provisioner "shell" {
    pause_before = "5s"
    inline = [
      "mkdir /home/vagrant/.ssh",
      "cp /tmp/authorized_keys /home/vagrant/.ssh/authorized_keys",
      "sudo chown -R vagrant: /home/vagrant/.ssh"
    ]
  }

  provisioner "ansible" {
    playbook_file = "./provisioning/playbook.yml"
    ansible_ssh_extra_args = ["-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa"]
    ## for debug
    #extra_arguments = [ "-vv" ]
    ## if we will use own ssh key
    #ssh_host_key_file = "./keys/ecdsa"
    #ssh_authorized_key_file = "./keys/ecdsa.pub"
    #ansible_env_vars = ["ANSIBLE_HOST_KEY_CHECKING=False"]
    #extra_arguments = ["-e ansible_ssh_private_key_file=./keys/ecdsa"]
  }

  post-processor "vagrant" {
    output = "./builds/{{.Provider}}-ubuntu2004.box"
  }

}
