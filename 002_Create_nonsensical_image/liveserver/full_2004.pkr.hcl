
source "virtualbox-iso" "ubu_lemp" {

  # See all types - "VBoxManage list ostypes | grep ubuntu"
  guest_os_type = "Ubuntu_64"

  iso_url = "http://releases.ubuntu.com/focal/ubuntu-20.04.4-live-server-amd64.iso"
  iso_checksum =  "sha256:28ccdb56450e643bad03bb7bcf7507ce3d8d90e8bf09e38f6bd9ac298a98eaad"

  #iso_url = "http://releases.ubuntu.com/jammy/ubuntu-22.04-live-server-amd64.iso"
  #iso_checksum =  "sha256:84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f"

  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_port = "22"
  ssh_wait_timeout = "60m"

  guest_additions_path = "VBoxGuestAdditions_{{.Version}}.iso"
  virtualbox_version_file = ".vbox_version"

  shutdown_command = "echo \"vagrant\" | sudo -S systemctl poweroff"
  shutdown_timeout = "10m"

  firmware = "bios"
  disk_size = "60000"
  hard_drive_interface = "sata"
  nic_type = "82543GC"

  vm_name = "ubu-lemp"

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

  sources = ["sources.virtualbox-iso.ubu_lemp"]

}
