
variables {
  v_ssh_username = "vagrant"
  v_ssh_password = "vagrant"
  v_iso_url = "http://releases.ubuntu.com/20.04.3/ubuntu-20.04.3-live-server-amd64.iso"
  v_iso_checksum = "sha256:f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98"
}


source "virtualbox-iso" "ubu_lamp" {

  # See all types - "VBoxManage list ostypes | grep ubuntu"
  guest_os_type = "Ubuntu_64"

  iso_url = "${var.v_iso_url}"
  iso_checksum =  "${var.v_iso_checksum}"

  ssh_username = "${var.v_ssh_username}"
  ssh_password = "${var.v_ssh_password}"
  ssh_port = "22"
  ssh_wait_timeout = "30m"

  guest_additions_path = "VBoxGuestAdditions_{{.Version}}.iso"
  virtualbox_version_file = ".vbox_version"

  shutdown_command = "echo \"vagrant\" | sudo -S systemctl poweroff"
  shutdown_timeout = "1m"

  firmware = "bios"
  disk_size = "60000"
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
    "<enter><enter><f6><esc><wait>",
    "autoinstall ds=nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/",
    "<enter>"
  ]

}

build {

  sources = ["sources.virtualbox-iso.ubu_lamp"]

  provisioner "ansible" {
    playbook_file = "./provisioning/playbook.yml"
    #ansible_ssh_extra_args = ["-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa"]
    ## for debug
    #extra_arguments = [ "-vv" ]
    ## if we will use own ssh key
    ssh_host_key_file = "./keys/ecdsa"
    ssh_authorized_key_file = "./keys/ecdsa.pub"
    ansible_env_vars = ["ANSIBLE_HOST_KEY_CHECKING=False"]
    extra_arguments = ["-e ansible_ssh_private_key_file=./keys/ecdsa"]
  }

  post-processor "vagrant" {
    output = "./builds/{{.Provider}}-ubuntu2004.box"
  }

}
