terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.6"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://${var.pm_host}:8006/api2/json"
  pm_user         = var.pm_user
  pm_password     = var.pm_password
  pm_tls_insecure = var.pm_tls_insecure
  pm_parallel     = 10
  pm_timeout      = 1200
  #  pm_debug = true
  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}
resource "proxmox_vm_qemu" "proxmox_vm_masters" {
  count       = var.num_k3s_masters
  name        = "k3s-master-${count.index}"
  target_node = var.pm_node_name
  clone       = var.template_vm_name
  os_type     = "cloud-init"
  agent       = 1
  memory      = var.num_k3s_masters_mem
  cores       = 4

  sshkeys = file(var.authorized_keys_file)
  nameserver = var.nameserver
  ciuser = var.ci_user

  ipconfig0 = "ip=${var.master_ips[count.index]}/${var.networkrange},gw=${var.gateway}"

  disk {
    size = var.size_k3s_masters_disk
    storage = "local"
    type = "scsi"
    format = var.disk_format
  }

  lifecycle {
    ignore_changes = [
      ciuser,
      sshkeys,
      disk,
      network
    ]
  }

}

resource "proxmox_vm_qemu" "proxmox_vm_workers" {
  count       = var.num_k3s_workers
  name        = "k3s-worker-${count.index}"
  target_node = var.pm_node_name
  clone       = var.template_vm_name
  os_type     = "cloud-init"
  agent       = 1
  memory      = var.num_k3s_workers_mem
  cores       = 4

  sshkeys = file(var.authorized_keys_file)
  nameserver = var.nameserver
  ciuser = var.ci_user

  ipconfig0 = "ip=${var.worker_ips[count.index]}/${var.networkrange},gw=${var.gateway}"

  disk {
    size = var.size_k3s_workers_disk
    storage = "local"
    type = "scsi"
    format = var.disk_format
  }

  lifecycle {
    ignore_changes = [
      ciuser,
      sshkeys,
      disk,
      network
    ]
  }  

}

data "template_file" "k8s" {
  template = file("./templates/k8s.tpl")
  vars = {
    k3s_master_ip = "${join("\n", [for instance in proxmox_vm_qemu.proxmox_vm_masters : join("", [instance.default_ipv4_address, " ansible_ssh_private_key_file=", var.pvt_key, " ansible_ssh_common_args='-o StrictHostKeyChecking=no' "])])}"
    k3s_node_ip   = "${join("\n", [for instance in proxmox_vm_qemu.proxmox_vm_workers : join("", [instance.default_ipv4_address, " ansible_ssh_private_key_file=", var.pvt_key, " ansible_ssh_common_args='-o StrictHostKeyChecking=no' "])])}"
  }
}

data "template_file" "all" {
  template = file("./templates/all.tpl")
  vars = {
    ci_user = var.ci_user
    metallb = var.metallb
    metallb_range = var.metallb_range
    peer_asn = var.peer_asn
    peer_address = var.peer_address
    my_asn: var.my_asn
  }
}

data "template_file" "egress_download" {
  template = file("./templates/egress_download.tpl")
  vars = {
    egress_ip_download = var.egress_ip_download
  }
}

data "template_file" "egress_pool_download" {
  template = file("./templates/egress_pool_download.tpl")
  vars = {
    egress_pool_start = var.egress_pool_start
    egress_pool_end = var.egress_pool_end
  }
}

resource "local_file" "k8s_file" {
  content  = data.template_file.k8s.rendered
  filename = "../inventory/${var.cluster_name}/hosts.ini"
  depends_on = [
    proxmox_vm_qemu.proxmox_vm_masters,
    proxmox_vm_qemu.proxmox_vm_workers,
  ]
}

resource "local_file" "var_file" {
  content  = data.template_file.all.rendered
  filename = "../inventory/${var.cluster_name}/group_vars/all.yml"
  depends_on = [
    proxmox_vm_qemu.proxmox_vm_masters,
    proxmox_vm_qemu.proxmox_vm_workers,
  ]
}

resource "local_file" "egress" {
  content  = data.template_file.egress_download.rendered
  filename = "../roles/postconfig/localhost/files/antrea/99-antrea_egress_download.yaml"
  depends_on = [
    proxmox_vm_qemu.proxmox_vm_masters,
    proxmox_vm_qemu.proxmox_vm_workers,
  ]
}

resource "local_file" "egress_pool" {
  content  = data.template_file.egress_pool_download.rendered
  filename = "../roles/postconfig/localhost/files/antrea/00-antrea_egress_pool_download.yaml"
  depends_on = [
    proxmox_vm_qemu.proxmox_vm_masters,
    proxmox_vm_qemu.proxmox_vm_workers,
  ]
}

output "Master-IPS" {
  value = ["${proxmox_vm_qemu.proxmox_vm_masters.*.default_ipv4_address}"]
}

output "worker-IPS" {
  value = ["${proxmox_vm_qemu.proxmox_vm_workers.*.default_ipv4_address}"]
}

resource "null_resource" "k3s_install" {
  provisioner "local-exec" {
    command = "sleep 120; /root/.venv/k3s/bin/ansible-playbook -i ../inventory/${var.cluster_name}/hosts.ini ../site.yml"
  }
  depends_on = [
    proxmox_vm_qemu.proxmox_vm_masters,
    proxmox_vm_qemu.proxmox_vm_workers,
    local_file.k8s_file,
    local_file.var_file,
    local_file.egress,
    local_file.egress_pool,
  ]
}
