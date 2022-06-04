source "virtualbox-iso" "ubu_lemp" {

  # See all types - "VBoxManage list ostypes | grep Ubuntu"
  guest_os_type = "Ubuntu_64"

  iso_url = "http://releases.ubuntu.com/focal/ubuntu-20.04.4-live-server-amd64.iso"
  iso_checksum = "sha256:28ccdb56450e643bad03bb7bcf7507ce3d8d90e8bf09e38f6bd9ac298a98eaad"

  ssh_username = "vagrant"
  ssh_password = "vagrant"

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

  boot_wait = "2s"
  headless = false

  http_directory = "./http"
  boot_command = [
    "<esc><wait1s>",                # pic-1
    "<esc><wait1s>",                # pic-2
    "<esc><wait1s>",                # pic-3
    "<esc><wait1s>",                # pic-4
    "<enter><wait1s>",              # pic-5
    "This is future LEMP image",
    "<enter>"                     # pic-6
  ]

}

build {

  sources = ["sources.virtualbox-iso.ubu_lemp"]

}
