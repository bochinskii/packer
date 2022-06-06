variables {
  instance_type = "t2.micro"
  volume_size = 8
  volume_type = "gp2"
}

data "amazon-ami" "amazon-linux-5" {
    filters = {
        virtualization-type = "hvm"
        name = "amzn2-ami-kernel-5*-x86_64-gp2"
        root-device-type = "ebs"
    }
    owners = ["amazon"]
    most_recent = true
}

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
