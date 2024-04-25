#!/usr/bin/env bash

set -o errexit -o nounset -o errtrace -o pipefail -x

kubectl create ns k8s-medusa 

# Function to retry a command until it succeeds or reaches max attempts
# Arguments:
#   $1: max_attempts
#   $2: interval (seconds)
#   $3: description of the operation
#   ${@:4}: command to execute
retry_command() {
    local max_attempts=$1
    local interval=$2
    local description=$3
    local cmd="${@:4}"
    local attempt=1

    echo "Retrying: $description"
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt: $cmd"
        if eval $cmd; then
            echo "Success on attempt $attempt for: $description"
            return 0
        else
            echo "Failure on attempt $attempt for: $description"
            sleep $interval
        fi
        ((attempt++))
    done

    echo "Error: Failed after $max_attempts attempts for: $description"
    return 1
}

# Check readiness of cert-manager pods
retry_command 5 15 "cert-manager pod readiness" "kubectl wait --for=condition=ready pod --selector app.kubernetes.io/instance=cert-manager --namespace ${NAMESPACE} --timeout=1m"


# Check readiness of k8sandra-operator
retry_command 5 15 "k8ssandra-operator pod readiness" "kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=k8ssandra-operator --namespace ${NAMESPACE} --timeout=1m"

kubectl apply -n "k8s-medusa" -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
 name: medusa-bucket-key
type: Opaque
stringData:
 # Note that this currently has to be set to credentials!
 credentials: |-
   [default]
   aws_access_key_id = k8ssandra
   aws_secret_access_key = k8ssandra
EOF

# Check readiness of the Cassandra Medusa pod
retry_command 5 15 "Cassandra Medusa pod readiness" "kubectl wait --for=condition=Ready pod -l app=medusa-cassandra-medusa-medusa-standalone -n ${NAMESPACE} --timeout=2m"

# Check readiness of the Cassandra stateful set
retry_command 20 30 "Cassandra stateful set readiness" "kubectl get statefulset medusa-cassandra-medusa-default-sts -n ${NAMESPACE} --no-headers -o custom-columns=READY:.status.readyReplicas | grep -q '1'"

# Check Medusa gRPC server startup
sleep 5
kubectl logs -l app=medusa-cassandra-medusa-medusa-standalone --tail -1 -n ${NAMESPACE} | grep "Starting server. Listening on port 50051"

# Create Medusa Backup
kubectl apply -n "k8s-medusa" -f - <<EOF
apiVersion: medusa.k8ssandra.io/v1alpha1
kind: MedusaBackup
metadata:
  name: medusa-backup
  namespace: ${NAMESPACE}
spec:
  backupType: full
  cassandraDatacenter: medusa 
EOF

# Verify creation of the MedusaBackup resource
retry_command 5 15 "MedusaBackup resource creation" "kubectl get medusabackup -n ${NAMESPACE} 2>&1 | grep -q 'medusa-backup'"
