#!/bin/bash
qm create 9000 --name "ubuntu-template" --memory 2048 --net0 virtio,bridge=vmbr0
qm importdisk 9000 --format qcow2 ubuntu-template.img local
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local:9000/vm-9000-disk-0.qcow2
qm set 9000 --ide2 local:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm template 9000
