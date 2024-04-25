#!/usr/bin/env bash

set -o errexit -o nounset -o errtrace -o pipefail -x

kubectl create ns minio

# Dependency: minio deployment
# **NOTE**: This approach is a lot more involved, but I aligned with how the
# upstream maintainer said they setup for testing. See:
# - https://github.com/k8ssandra/k8ssandra-operator/issues/1185#issuecomment-1906230025
kubectl apply -n minio -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: minio
  name: minio
  namespace: minio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
      - name: minio
        image: quay.io/minio/minio:latest
        command:
        - /bin/bash
        - -c
        args:
        - minio server /data --console-address :9090
        volumeMounts:
        - mountPath: /data
          name: localvolume
      volumes:
      - name: localvolume
        emptyDir:
          sizeLimit: 500Mi
EOF

# Dependency: minio service
kubectl apply -n minio -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: minio-service
  namespace: minio
spec:
  selector:
    app: minio
  ports:
    - protocol: TCP
      name: api
      port: 9000
      targetPort: 9000
    - protocol: TCP
      name: admin-console
      port: 9090
      targetPort: 9090
EOF

# Dependency: Run minio
kubectl apply -n minio -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: setup-minio
spec:
  template:
    spec:
      restartPolicy: OnFailure
      containers:
        - name: setup-minio-pod
          image: minio/mc
          command: ["bash", "-c"]
          args:
            - |
              mc alias set k8s-minio http://minio-service.${NAMESPACE}.svc.cluster.local:9000 minioadmin minioadmin
              mc mb k8s-minio/k8ssandra-medusa
              mc admin user add k8s-minio k8ssandra k8ssandra
              mc admin policy attach k8s-minio readwrite --user k8ssandra
EOF