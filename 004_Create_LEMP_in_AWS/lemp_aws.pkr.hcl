variables {
  access_key = "${env("access_key")}"
  secret_key = "${env("secret_key")}"
  region = "eu-centarl-1"
  instance_type = "t2.micro"
  source_ami =
  v_iso_url = "http://releases.ubuntu.com/jammy/ubuntu-22.04-live-server-amd64.iso"
  v_iso_checksum = "sha256:84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f"
}

source "amazon-ebs" "rocinante-lemp" {

  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"


  ami_name = "rocinante-lemp-ami"
  instance_type = "${var.instance_type}"
  source_ami = "${var.source_ami}"

  ssh_username = "ec2-user"
}


build {

  provisioner "shell" {
    pause_before = "5s"
    script       = "./provisioning/script.sh"
    timeout      = "10s"
  }

  provisioner "file" {
    pause_before = "5s"
    source = "./provisioning/configs.tar.bz"
    destination = "/tmp/configs.tar.bz"
  }

  provisioner "shell" {
    pause_before = "5s"
    inline = [
      "sudo tar -xf configs.tar.bz",
      "sudo mv -f /configs/nginx.conf /etc/nginx/",
      "sudo mv -f /configs/*.conf /etc/nginx/conf.d/",
      "sudo mv -f /configs/php.ini /etc/",
      "sudo mv -f /configs/my.cnf /etc/",
      "sudo systemctl restart mysqld",
      "sudo systemctl restart php-fpm",
      "sudo systemctl restart nginx"
    ]
  }

}
