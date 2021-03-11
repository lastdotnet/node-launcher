#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short

if ! node_exists; then
  die "No existing THORNode found, make sure this is the correct name"
fi

echo "=> Exporting THORNode chain state from $boldgreen$NAME$reset"
confirm

DATE=$(date +%s)
IMAGE=$(kubectl -n "$NAME" get deploy/thornode -o jsonpath='{$.spec.template.spec.containers[:1].image}')
SPEC="
{
  \"apiVersion\": \"v1\",
  \"spec\": {
    \"containers\": [
      {
        \"command\": [
          \"sh\",
          \"-c\",
          \"printf \\\"\\n\\n\\\" | thornode export\"
        ],
        \"name\": \"export-state\",
        \"stdin\": true,
        \"tty\": true,
        \"image\": \"$IMAGE\",
        \"volumeMounts\": [{\"mountPath\": \"/root\", \"name\":\"data\"}]
      }
    ],
    \"volumes\": [{\"name\": \"data\", \"persistentVolumeClaim\": {\"claimName\": \"thornode\"}}]
  }
}"

kubectl scale -n "$NAME" --replicas=0 deploy/thornode --timeout=5m
kubectl wait --for=delete pods -l app.kubernetes.io/name=thornode -n "$NAME" --timeout=5m > /dev/null 2>&1 || true
kubectl run -n "$NAME" -it --quiet export-state --restart=Never --image="$IMAGE" --overrides="$SPEC" > "genesis.$DATE.json"
kubectl -n "$NAME" delete pod export-state --wait=false
kubectl scale -n "$NAME" --replicas=1 deploy/thornode --timeout=5m
