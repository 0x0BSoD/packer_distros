# ====== VARS =============
variable "boot_wait" {
  type    = string
}
variable "disk_size" {
  type    = string
}
variable "iso_checksum" {
  type    = string
}
variable "iso_url" {
  type    = string
}
variable "memsize" {
  type    = string
}
variable "numvcpus" {
  type    = string
}
variable "ssh_password" {
  type    = string
}
variable "ssh_username" {
  type    = string
}
variable "vm_name" {
  type    = string
}
# / ====== VARS =============

# "timestamp" template function replacement
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "vmware-iso" "ol8_box" {
  iso_checksum     = "${var.iso_checksum}"
  iso_url          = "${var.iso_url}"
  // guest_os_type    = "Oracle_64"
  headless         = false
  shutdown_command = "echo 'vagrant'|sudo -S /sbin/halt -h -p"
  
  keep_registered  = true
  skip_export      = true
  format           = "vmx"

  vm_name          = "${var.vm_name}"

  http_directory   = "http"
  boot_command     = ["<tab><bs><bs><bs><bs><bs>text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg vga=833<enter><wait>"]
  boot_wait        = "${var.boot_wait}"

  cpus             = 1
  cores            = "${var.numvcpus}"
  memory           = "${var.memsize}"
  disk_size        = "${var.disk_size}"

  ssh_username     = "${var.ssh_username}"
  ssh_password     = "${var.ssh_password}"
  ssh_port         = 22
  ssh_timeout      = "30m"
}

build {
  sources = ["source.vmware-iso.ol8_box"]

  provisioner "shell" {
    execute_command = "echo 'vagrant'|{{.Vars}} sudo -S -E bash '{{.Path}}'"
    inline = ["dnf -y update",
    "dnf -y install python3",
    "alternatives --set python /usr/bin/python3",
    "pip3 install ansible"]
  }

  provisioner "ansible-local" {
    playbook_file   = "./provision/ansible/main.yml"
  }

  provisioner "shell" {
    execute_command = "echo 'vagrant'|{{.Vars}} sudo -S -E bash '{{.Path}}'"
    scripts = ["scripts/cleanup.sh"]
  }

  // post-processor "vagrant" {
  //   compression_level = 1
  //   output            = "${ var.vm_name}_{{.Provider}}.box"
  // }
}

