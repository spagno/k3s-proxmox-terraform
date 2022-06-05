variable "pm_user" {
  description = "The username for the proxmox user"
  type        = string
  sensitive = false
  default = "root@pam"

}
variable "pm_password" {
  description = "The password for the proxmox user"
  type        = string
  sensitive = true
}

variable "pm_tls_insecure" {
  description = "Set to true to ignore certificate errors"
  type = bool
  default = false
}

variable "pm_host" {
  description = "The hostname or IP of the proxmox server"
  type        = string
}

variable "pm_node_name" {
  description = "name of the proxmox node to create the VMs on"
  type = string
  default = "pve"
}

variable "pvt_key" {}

variable "num_k3s_masters" {
 default = 1
}

variable "num_k3s_masters_mem" {
 default = "4096"
}

variable "num_k3s_workers" {
 default = 2
}

variable "num_k3s_workers_mem" {
 default = "4096"
}

variable "template_vm_name" {}

variable "master_ips" {
  description = "List of ip addresses for master workers"
}

variable "worker_ips" {
  description = "List of ip addresses for worker nodes"
}

variable "networkrange" {
  default = 24
}

variable "gateway" {
  default = "192.168.3.1"
}

variable "cluster_name" {
  default = "my-inventory"
}

variable "size_k3s_masters_disk" {}

variable "size_k3s_workers_disk" {}

variable "disk_format" {}

variable "authorized_keys_file" {}

variable "nameserver" {}

variable "metallb" {}

variable "metallb_range" {}

variable "ci_user" {}

variable "my_asn" {}
variable "peer_asn" {}
variable "peer_address" {}

variable "egress_ip_download" {}

variable "egress_pool_start" {}
variable "egress_pool_end" {}
