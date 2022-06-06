#
# Variables
#
variables {
  instance_type = "t2.micro"
  volume_size = 8
  volume_type = "gp2"
  hostname = "rocinante.int"
  timezone = "Europe/Berlin"
  ssh_port = "${env("SSH_PORT")}"
  mysql_repo = "https://dev.mysql.com/get/mysql80-community-release-el7-6.noarch.rpm"
  mysql_root_pass = "${env("MYSQL_ROOT_PASS")}"
  mysql_admin_user = "${env("MYSQL_ADMIN_USER")}"
  mysql_admin_user_pass = "${env("MYSQL_ADMIN_USER_PASS")}"
  mysql_drupal_user = "${env("MYSQL_DRUPAL_USER")}"
  mysql_drupal_user_pass = "${env("MYSQL_DRUPAL_USER_PASS")}"
  mysql_drupal_db = "${env("MYSQL_DRUPAL_DB")}"
  ssl_cert = "rocinante.crt"
  ssl_key = "rocinante.key"
  site_dir = "/var/www/html/rocinante"
  site_config = "rocinante.conf"
}

variable "pkgs" {
  type = list(string)
  default = [
    "php", "php-fpm", "php-pdo", "php-mysqlnd", "php-xml", "php-gd", "php-curl",
    "php-mbstring", "php-json", "php-common", "php-gmp", "php-intl", "php-gd", "php-cli", "php-zip", "php-opcache"
  ]
}

#
# Latest Amazon Linux
#

data "amazon-ami" "amazon-linux-5" {
    filters = {
        virtualization-type = "hvm"
        name = "amzn2-ami-kernel-5*-x86_64-gp2"
        root-device-type = "ebs"
    }
    owners = ["amazon"]
    most_recent = true
}

#
# Main settings
#

source "amazon-ebs" "rocinante-lemp" {

  ami_name = "rocinante-lemp-ami"
  instance_type = "${var.instance_type}"
  source_ami = data.amazon-ami.amazon-linux-5.id
  ssh_username = "ec2-user"

  launch_block_device_mappings {
    device_name = "/dev/xvda"
    delete_on_termination = true
    volume_type = "${var.volume_type}"
    volume_size = "${var.volume_size}"
  }

}


build {

  sources = [
    "source.amazon-ebs.rocinante-lemp"
  ]

  provisioner "shell" {
    pause_before = "5s"
    inline = [templatefile("./provisioning/script_secure.sh.pkrtpl",
    {
      hostname = "${var.hostname}",
      timezone = "${var.timezone}",
      ssh_port = "${var.ssh_port}",
      mysql_repo = "${var.mysql_repo}",
      mysql_root_pass = "${var.mysql_root_pass}",
      mysql_admin_user = "${var.mysql_admin_user}",
      mysql_admin_user_pass = "${var.mysql_admin_user_pass}",
      mysql_drupal_user = "${var.mysql_drupal_user}",
      mysql_drupal_user_pass = "${var.mysql_drupal_user_pass}",
      mysql_drupal_db = "${var.mysql_drupal_db}",
      pkgs = "${var.pkgs}",
      ssl_cert = "${var.ssl_cert}",
      ssl_key = "${var.ssl_key}",
      site_dir = "${var.site_dir}",
      site_config = "${var.site_config}"
    }
    )]
    timeout = "10s"
  }

  provisioner "file" {
    pause_before = "5s"
    source = "./provisioning/configs.tar.bz"
    destination = "/tmp/configs.tar.bz"
  }

  provisioner "shell" {
    pause_before = "5s"
    inline = [
      "sudo tar -xvf /tmp/configs.tar.bz -C /tmp/",
      "sudo mv -f /tmp/configs/nginx.conf /etc/nginx/",
      "sudo mv -f /tmp/configs/*.conf /etc/nginx/conf.d/",
      "sudo mv -f /tmp/configs/php.ini /etc/",
      "sudo mv -f /tmp/configs/my.cnf /etc/",
      "sudo systemctl restart mysqld",
      "sudo systemctl restart php-fpm",
      "sudo systemctl restart nginx"
    ]
  }

}
