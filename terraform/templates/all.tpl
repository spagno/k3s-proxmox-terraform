---
k3s_version: v1.22.2+k3s1
ansible_user: ${ci_user}
systemd_dir: /etc/systemd/system
master_ip: "{{ hostvars[groups['master'][0]]['ansible_host'] | default(groups['master'][0]) }}"
extra_server_args: "--write-kubeconfig-mode=644"
extra_agent_args: ""
copy_kubeconfig: true
metallb: ${metallb}
metallb_version: "v0.12.1"
metallb_range: ${metallb_range}
peer_address: ${peer_address}
my_asn: ${my_asn}
peer_asn: ${peer_asn}
