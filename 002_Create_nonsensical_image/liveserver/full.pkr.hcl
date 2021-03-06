
source "virtualbox-iso" "ubu_lemp" {

  # See all types - "VBoxManage list ostypes | grep ubuntu"
  guest_os_type = "Ubuntu_64"

  iso_url = "http://releases.ubuntu.com/jammy/ubuntu-22.04-live-server-amd64.iso"
  iso_checksum =  "sha256:84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f"

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

  sources = ["sources.virtualbox-iso.ubu_lemp"]

}
