#!/bin/bash

# ============================================================
# Lab 13 — Create Kubernetes Secret
# INET 4031 — Systems Administration
# ============================================================
# 1. Open this file in VSCode
# 2. Replace YOUR_ROOT_PASSWORD and YOUR_PASSWORD with the
#    same values you used in your Lab 12 .env file
# 3. Save the file
# 4. Run: bash create-secret.sh
#
# This file is safe to commit as long as you leave the
# placeholder values in place. Only change them locally.
# ============================================================

MARIADB_ROOT_PASSWORD="YOUR_ROOT_PASSWORD"
MARIADB_DATABASE="ticketdb"
MARIADB_USER="flaskuser"
MARIADB_PASSWORD="YOUR_PASSWORD"

# These mirror the values above for the Flask app
DB_HOST="db"
DB_NAME="ticketdb"
DB_USER="flaskuser"
DB_PASSWORD="YOUR_PASSWORD"

# ============================================================
# Do not edit below this line
# ============================================================

NAMESPACE="ticket-app"

# Check that the user has filled in their values
if [[ "$MARIADB_ROOT_PASSWORD" == "YOUR_ROOT_PASSWORD" || "$MARIADB_PASSWORD" == "YOUR_PASSWORD" ]]; then
  echo "[ERROR] You have not replaced the placeholder passwords."
  echo "        Open create-secret.sh in VSCode and update the values at the top."
  exit 1
fi

# Check that the namespace exists
if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
  echo "[ERROR] Namespace '$NAMESPACE' does not exist."
  echo "        Run: kubectl create namespace $NAMESPACE"
  exit 1
fi

# Check if the secret already exists and delete it first
if kubectl get secret db-credentials -n "$NAMESPACE" &>/dev/null; then
  echo "[INFO] Secret 'db-credentials' already exists. Deleting and recreating..."
  kubectl delete secret db-credentials -n "$NAMESPACE"
fi

kubectl create secret generic db-credentials \
  --from-literal=MARIADB_ROOT_PASSWORD="$MARIADB_ROOT_PASSWORD" \
  --from-literal=MARIADB_DATABASE="$MARIADB_DATABASE" \
  --from-literal=MARIADB_USER="$MARIADB_USER" \
  --from-literal=MARIADB_PASSWORD="$MARIADB_PASSWORD" \
  --from-literal=DB_HOST="$DB_HOST" \
  --from-literal=DB_NAME="$DB_NAME" \
  --from-literal=DB_USER="$DB_USER" \
  --from-literal=DB_PASSWORD="$DB_PASSWORD" \
  -n "$NAMESPACE"

if [ $? -eq 0 ]; then
  echo "[OK] Secret 'db-credentials' created in namespace '$NAMESPACE'."
  echo "     Run: kubectl describe secret db-credentials -n $NAMESPACE"
else
  echo "[ERROR] Failed to create secret. Check the error above."
fi
