
variables {
  v_ssh_username = "vagrant"
  v_ssh_password = "vagrant"
  # If we want use Enviroment Variables
  # The first step: # export V_SSH_USERNAME=vagrant && export V_SSH_PASSWORD=vagrant
  # The second step:
  # v_ssh_username = "${env("V_SSH_USERNAME")}"
  # v_ssh_password = "${env("V_SSH_PASSWORD")}"
  v_iso_url = "http://releases.ubuntu.com/jammy/ubuntu-22.04-live-server-amd64.iso"
  v_iso_checksum = "sha256:84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f"
}


source "virtualbox-iso" "ubu_lamp" {

  # See all types - "VBoxManage list ostypes | grep ubuntu"
  guest_os_type = "Ubuntu_64"

  iso_url = "${var.v_iso_url}"
  iso_checksum =  "${var.v_iso_checksum}"

  ssh_username = "${var.v_ssh_username}"
  ssh_password = "${var.v_ssh_password}"
  ssh_port = "22"
  ssh_wait_timeout = "60m"

  guest_additions_path = "VBoxGuestAdditions_{{.Version}}.iso"
  virtualbox_version_file = ".vbox_version"

  shutdown_command = "echo \"vagrant\" | sudo -S systemctl poweroff"
  shutdown_timeout = "10m"

  firmware = "bios"
  disk_size = "12000"
  hard_drive_interface = "sata"
  nic_type = "82543GC"

  vm_name = "ubu-lamp"

  cpus = "6"
  memory = "4096"
  sound = "none"
  usb = false

  boot_wait = "3s"
  headless = false

  http_directory = "./http"
  boot_command = [
    "<esc><esc><esc><esc>e<wait>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/\"<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>",
    "<enter><f10><wait>"
  ]

}

build {

  sources = ["sources.virtualbox-iso.ubu_lamp"]

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
    output = "./builds/{{.Provider}}-ubuntu2204.box"
  }

}
