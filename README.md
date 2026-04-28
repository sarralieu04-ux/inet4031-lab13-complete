# INET4031_lab12 - Alieu Sarr

Scalable Ticket Dashboard

This repository contains a full-stack containerized application deployed onto a K3s  cluster for my INET4031 lab 13. This lab directly builds off of Lab 12. The application consists of a MariaDB database, a Flask Python API, and an Apache web frontend
Architecture.

The application is split into three  layers, each running in its own Kubernetes Pod:
**Database - MariaDB: Stores ticket data. Uses a PersistentVolumeClaim to ensure data persists even if the pod restarts.
**Backend - Flask: A Python API that connects to the database to serve ticket information as JSON.
**Frontend - Apache: A public-facing web server that proxies requests to the Flask backend and serves the dashboard UI.


1. Prerequisites
A running K3s or Kubernetes cluster.
kubectl configured with admin permissions.
Docker images for the app and web components pushed to a registry (In my case it was DockerHub).

2. Applying Manifests
Kubernetes Secrets are used to manage the sensitive database credentials required for the application to function. The process involves creating a Secret object within the specific application namespace before any pods are deployed. This ensures that sensitive information, such as the database root password and user credentials, is stored securely within the cluster rather than being hardcoded into the manifest files or version control.
During the setup, I mapped variables from a local environment file to the Secret. Because the MariaDB container requires specific naming conventions for its environment variables, I had to ensured the keys in the Secret aligned with the requirements of the database image. These secrets are then injected into the backend and database pods as environment variables, allowing the services to authenticate with one another securely.

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
