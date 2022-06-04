source "virtualbox-iso" "ubu_lemp" {

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
  disk_size = "60000"
  hard_drive_interface = "sata"
  nic_type = "82543GC"

  vm_name = "ubu-lemp"

  cpus = "6"
  memory = "4096"
  sound = "none"
  usb = false

  boot_wait = "10s"
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
    " netcfg/get_hostname=ubu-lemp<wait1s>",
    " -- <wait1s>",
    "<enter><wait1s>"
  ]

}

build {

  sources = ["sources.virtualbox-iso.ubu_lemp"]

}
