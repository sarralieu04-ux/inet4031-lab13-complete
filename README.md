# INET4031_lab12 - Alieu Sarr

Scalable Ticket Dashboard
This repository contains a full-stack containerized application deployed onto a K3s (Kubernetes) cluster. The application consists of a MariaDB database, a Flask Python API, and an Apache web frontend.
Architecture
The application is split into three distinct layers, each running in its own Kubernetes Pod:
Database (MariaDB): Stores ticket data. Uses a PersistentVolumeClaim (PVC) to ensure data persists even if the pod restarts.
Backend (Flask): A Python API that connects to the database to serve ticket information as JSON.
Frontend (Apache): A public-facing web server that proxies requests to the Flask backend and serves the dashboard UI.


1. Prerequisites
A running K3s or Kubernetes cluster.
kubectl configured with admin permissions.
Docker images for the app and web components pushed to a registry (example: Docker Hub).

Check Logs
  Database: kubectl logs -n ticket-app deployment/db
  Flask App: kubectl logs -n ticket-app deployment/app
  Web Server: kubectl logs -n ticket-app deployment/web

Accessing the App
The application is exposed via a NodePort on port 30080.
I accessed it at: http://192.168.56.102:30080
Lab Verification
to verify all portions of the lab were working:
  chmod +x check-lab13.sh
  ./check-lab13.sh
