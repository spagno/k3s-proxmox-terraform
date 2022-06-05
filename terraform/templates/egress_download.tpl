apiVersion: crd.antrea.io/v1alpha2
kind: Egress
metadata:
  name: egress
spec:
  appliedTo:
    namespaceSelector:
      matchLabels:
        egress: pool-download
  egressIP: ${egress_ip_download}
  externalIPPool: egress-pool-download
