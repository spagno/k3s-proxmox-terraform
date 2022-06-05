apiVersion: crd.antrea.io/v1alpha2
kind: ExternalIPPool
metadata:
  name: egress-pool-download
spec:
  ipRanges:
  - start: ${egress_pool_start}
    end: ${egress_pool_end}
  nodeSelector: {}
