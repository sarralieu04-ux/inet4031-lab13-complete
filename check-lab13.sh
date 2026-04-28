#!/bin/bash

# ============================================================
# Lab 13 Check Script — Kubernetes with k3s
# INET 4031 — Systems Administration
# ============================================================
# Run from your repo root:
#   chmod +x check-lab13.sh
#   ./check-lab13.sh
# ============================================================

NAMESPACE="ticket-app"
PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check() {
  local description="$1"
  local result="$2"
  local hint="$3"

  if [ "$result" -eq 0 ]; then
    echo -e "  ${GREEN}[PASS]${NC} $description"
    ((PASS++))
  else
    echo -e "  ${RED}[FAIL]${NC} $description"
    echo -e "         ${YELLOW}Hint:${NC} $hint"
    ((FAIL++))
  fi
}

echo ""
echo "============================================"
echo "  Lab 13 Check Script — k3s Deployment"
echo "============================================"
echo ""

# --------------------------------------------
# 1. k3s Installation
# --------------------------------------------
echo "[ Cluster ]"

command -v kubectl &>/dev/null
check "kubectl is available" $? \
  "k3s may not be installed. Run: curl -sfL https://get.k3s.io | sh -"

kubectl get nodes &>/dev/null 2>&1
NODE_STATUS=$(kubectl get nodes --no-headers 2>/dev/null | awk '{print $2}' | head -1)
[ "$NODE_STATUS" = "Ready" ]
check "Cluster node is Ready" $? \
  "Run: kubectl get nodes — if NotReady, wait 60 seconds and retry"

echo ""

# --------------------------------------------
# 2. Namespace and Secret
# --------------------------------------------
echo "[ Namespace & Secret ]"

kubectl get namespace "$NAMESPACE" &>/dev/null
check "Namespace 'ticket-app' exists" $? \
  "Run: kubectl create namespace ticket-app"

kubectl get secret db-credentials -n "$NAMESPACE" &>/dev/null
check "Secret 'db-credentials' exists" $? \
  "Edit create-secret.sh with your credentials, then run: bash create-secret.sh"

echo ""

# --------------------------------------------
# 3. Deployments
# --------------------------------------------
echo "[ Deployments ]"

for deploy in db app web; do
  kubectl get deployment "$deploy" -n "$NAMESPACE" &>/dev/null
  check "Deployment '$deploy' exists" $? \
    "Run: kubectl apply -f k8s/ — then check k8s/${deploy}-deployment.yaml for blank fields"
done

echo ""

# --------------------------------------------
# 4. Pods Running
# --------------------------------------------
echo "[ Pods ]"

for deploy in db app web; do
  READY=$(kubectl get deployment "$deploy" -n "$NAMESPACE" --no-headers 2>/dev/null | awk '{print $2}')
  [ "$READY" = "1/1" ]
  check "Pod for '$deploy' is Running and Ready" $? \
    "Run: kubectl logs -n $NAMESPACE deployment/$deploy — check for image pull errors or missing env vars"
done

echo ""

# --------------------------------------------
# 5. Storage
# --------------------------------------------
echo "[ Storage ]"

PVC_STATUS=$(kubectl get pvc db-pvc -n "$NAMESPACE" --no-headers 2>/dev/null | awk '{print $2}')
[ "$PVC_STATUS" = "Bound" ]
check "PVC 'db-pvc' is Bound" $? \
  "Run: kubectl describe pvc db-pvc -n $NAMESPACE — the local-path provisioner may still be starting"

echo ""

# --------------------------------------------
# 6. Manifest Files
# --------------------------------------------
echo "[ Manifest Files ]"

for file in db-deployment.yaml app-deployment.yaml web-deployment.yaml; do
  [ -f "k8s/$file" ]
  check "k8s/$file exists" $? \
    "This file should have been created during the lab. Check that git pull completed successfully."
done

echo ""

# --------------------------------------------
# 7. Application Endpoints
# --------------------------------------------
echo "[ Application ]"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:30080 2>/dev/null)
[[ "$HTTP_CODE" =~ ^(200|301|302|403)$ ]]
check "Apache responds on port 30080" $? \
  "Run: kubectl get service web -n $NAMESPACE — confirm type is NodePort and nodePort is 30080"

HEALTH=$(curl -s --max-time 5 http://localhost:30080/health 2>/dev/null)
echo "$HEALTH" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    assert d.get('status') == 'healthy'
except:
    sys.exit(1)
" &>/dev/null
check "Flask /health returns status: healthy" $? \
  "Run: kubectl logs -n $NAMESPACE deployment/app — MariaDB may still be initializing, wait and retry"

TICKETS=$(curl -s --max-time 5 http://localhost:30080/api/tickets 2>/dev/null)
echo "$TICKETS" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    assert isinstance(d, list)
except:
    sys.exit(1)
" &>/dev/null
check "Flask /api/tickets returns a JSON array" $? \
  "Run: curl http://localhost:30080/api/tickets — check Flask and MariaDB logs if empty or error"

echo ""

# --------------------------------------------
# Results
# --------------------------------------------
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -eq 0 ]; then
  echo -e "  ${GREEN}All checks passed!${NC}"
  echo "  Commit your manifests, update your README, and push to GitHub."
else
  echo -e "  ${RED}$FAIL check(s) failed.${NC} Fix the issues above and re-run ./check-lab13.sh"
  echo ""
  echo "  Useful commands:"
  echo "    kubectl get pods -n $NAMESPACE"
  echo "    kubectl describe pod <pod-name> -n $NAMESPACE"
  echo "    kubectl logs -n $NAMESPACE deployment/app"
  echo "    kubectl logs -n $NAMESPACE deployment/db"
  echo "    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'"
fi

echo ""
