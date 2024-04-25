#!/usr/bin/env bash

set -o errexit -o nounset -o errtrace -o pipefail -x

# Create K8ssandraCluster
kubectl apply -n k8ssandra -f - <<EOF
apiVersion: k8ssandra.io/v1alpha1
kind: K8ssandraCluster
metadata:
  name: medusa
  namespace: k8ssandra
spec:
  cassandra:
    serverVersion: "4.0.1"
    datacenters:
      - metadata:
          name: medusa
        size: 1
        storageConfig:
          cassandraDataVolumeClaimSpec:
            storageClassName: local-path
            accessModes:
              - ReadWriteOnce
            resources:
              requests:
                storage: 1Gi
        config:
          jvmOptions:
            heapSize: 512M
        stargate:
          size: 1
          heapSize: 256M
          affinity:
            podAntiAffinity:
              preferredDuringSchedulingIgnoredDuringExecution:
                - weight: 1
                  podAffinityTerm:
                    labelSelector:
                      matchLabels:
                        "app.kubernetes.io/name": "stargate"
                    topologyKey: "kubernetes.io/hostname"
  medusa:
    storageProperties:
      storageProvider: s3_compatible
      bucketName: k8ssandra-medusa
      prefix: test
      storageSecretRef:
        name: medusa-bucket-key
      host: minio-service.minio.svc.cluster.local
      port: 9000
      secure: false
EOF