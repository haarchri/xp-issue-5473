#!/bin/bash
set -e

KUBECTL=kubectl

kind create cluster --name=issue-base-template
kubectx kind-issue-base-template

kubectl create namespace upbound-system

helm install uxp --namespace upbound-system upbound-stable/universal-crossplane --version $1 --wait
kubectl -n upbound-system wait deploy crossplane --for condition=Available --timeout=60s

echo "Creating cloud credential secret..."
"${KUBECTL}" -n upbound-system create secret generic aws-creds --from-literal=credentials="${UPTEST_CLOUD_CREDENTIALS}" \
    --dry-run=client -o yaml | "${KUBECTL}" apply -f -

cat <<EOF | "${KUBECTL}" apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-iam
spec:
  package: xpkg.upbound.io/upbound/provider-aws-iam:v0.47.3
EOF


cat <<EOF | "${KUBECTL}" apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-aws:v0.47.0
EOF

echo "Waiting until all installed provider packages are healthy..."
"${KUBECTL}" wait provider.pkg --all --for condition=Healthy --timeout 5m

echo "Waiting for all pods to come online..."
"${KUBECTL}" -n upbound-system wait --for=condition=Available deployment --all --timeout=5m

echo "Creating a default provider config..."
cat <<EOF | "${KUBECTL}" apply -f -
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    secretRef:
      key: credentials
      name: aws-creds
      namespace: upbound-system
    source: Secret
EOF

cat <<EOF | "${KUBECTL}" apply -f -
apiVersion: aws.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    secretRef:
      key: credentials
      name: aws-creds
      namespace: upbound-system
    source: Secret
EOF

"${KUBECTL}" apply -f apis/definition.yaml
"${KUBECTL}" apply -f apis/composition-community.yaml
sleep 30
"${KUBECTL}" apply -f claim.yaml
sleep 30
"${KUBECTL}" apply -f apis/composition-official.yaml
sleep 90
"${KUBECTL}" get xacmedatabases  -o jsonpath='{.items[*].spec.resourceRefs}'
