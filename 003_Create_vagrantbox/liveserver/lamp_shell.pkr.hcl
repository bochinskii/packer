
source "virtualbox-iso" "ubu_lamp" {

  # See all types - "VBoxManage list ostypes | grep ubuntu"
  guest_os_type = "Ubuntu_64"

  iso_url = "http://releases.ubuntu.com/jammy/ubuntu-22.04-live-server-amd64.iso"
  iso_checksum =  "sha256:84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f"

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

  # Content Settings
  provisioner "shell" {
    pause_before = "5s"
    inline = [
      "sudo apt-get update",
      "sudo apt-get install lsb-release ca-certificates apt-transport-https software-properties-common -y",
      "sudo add-apt-repository ppa:ondrej/php -y",
      "sudo apt-get update",
      # Install Apache
      "sudo apt-get install apache2 apache2-utils -y",
      "sudo systemctl enable apache2 && sudo systemctl start apache2",
      # Install DB
      "sudo apt-get install mariadb-server mariadb-client -y",
      "sudo systemctl enable mariadb && sudo systemctl start mariadb",
      # Install PHP
      "sudo apt-get install php8.1 php8.1-fpm libapache2-mod-php8.1 php8.1-mysql php-common php8.1-cli php8.1-common php8.1-opcache php8.1-readline php8.1-mbstring php8.1-xml php8.1-gd php8.1-curl -y",
      "sudo a2enmod proxy_fcgi setenvif",
      "sudo a2enconf php8.1-fpm",
      "sudo systemctl restart mariadb",
      "sudo systemctl restart php8.1-fpm",
      "sudo systemctl restart apache2"
    ]
  }

  provisioner "file" {
    pause_before = "5s"
    source = "./files/index.html"
    destination = "/tmp/index.html"
  }

  provisioner "file" {
    pause_before = "5s"
    source = "./files/info.php"
    destination = "/tmp/info.php"
  }

  provisioner "shell" {
    pause_before = "5s"
    inline = [
      "sudo cp /tmp/index.html /var/www/html",
      "sudo cp /tmp/info.php /var/www/html",
      "sudo chown -R www-data:www-data /var/www/html"
    ]
  }

  post-processor "vagrant" {
    output = "./builds/{{.Provider}}-ubuntu2204.box"
  }

}
