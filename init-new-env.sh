#!/bin/bash

set -e

read -p """
  WARNING! You're about to initialize a new environment...
  Before proceed make sure to create/duplicate a GKE cluster on your GCP environment.
  Press [Enter] when the cluster is ready to continue or [Ctrl+C] to abort.
""" -n 1 -r

read -p "Enter the name of your new environment: " environment
read -p "Enter the GKE cluster name: " cluster_name
read -p "Enter the GKE cluster localtion (ej: europe-west1): " cluster_location
read -p "Enter the domain name of your new environment (ej: mysupercluster.com): " domain
read -p "Enter the Git branch you want to deploy from: " branch

read -p """
------------------------------------------------------
You're about to initialize a new environment corresponding to the following configuration:
  Environment: $environment
  Cluster name: $cluster_name
  Cluster location: $cluster_location
  Domain: $domain
  Git branch: $branch
------------------------------------------------------
Press [Enter] to continue or [Ctrl+C] to abort.
""" -n 1 -r

echo "Initializing new environment..."
echo "Creating the new Terraform workspace and value file..."
cd terraform && terraform workspace new "$environment" > /dev/null
echo """
cluster_name = \"$cluster_name\"
cluster_location = \"$cluster_location\"
dns_domain = \"$domain\"
""" > ./environments/"$environment".tfvars
cd -
printf "\e[32mOK\e[0m\n"

echo "Creating a dedicated Github Action workflow..."
echo """
name: Deploy $environment (with Terraform)

on:
  push:
    branches:
      - $branch

env:
  GKE_CLUSTER_NAME: $cluster_name
  GKE_REGION: $cluster_location
  GKE_ENV: $environment

jobs:
  deploy:
    name: Deploy
    runs-on: ubuntu-18.04
    timeout-minutes: 30
    permissions:
      contents: 'read'
      id-token: 'write'
    steps:
      - uses: actions/checkout@v2
      - id: 'auth'
        name: 'Authenticate to Google Cloud'
        uses: 'google-github-actions/auth@v0'
        with:
          credentials_json: '\${{ secrets.GKE_SA_KEY }}'
      - id: 'get-credentials'
        uses: 'google-github-actions/get-gke-credentials@v0'
        with:
          cluster_name: \${{ env.GKE_CLUSTER_NAME }}
          location: \${{ env.GKE_REGION }}
      - uses: azure/setup-helm@v1
        with:
          version: '3.7.2'
      - name: Deploy
        run: |
          cd terraform/
          terraform init
          terraform workspace select \$GKE_ENV
          terraform workspace list
          terraform apply -auto-approve -var-file=environments/\$GKE_ENV.tfvars
        env:
          GOOGLE_CREDENTIALS: \${{ secrets.GKE_SA_KEY }}
""" > ./.github/workflows/push-"$branch".yaml
printf "\e[32mOK\e[0m\n"

echo "Creating a dedicated Git branch..."
git checkout -b "$branch"
printf "\e[32mOK\e[0m\n"

read -p "Do you want to deploy the new environment now? [y/N]: " deploy
if [ "$deploy" == "y" ]; then
  echo "Deploying the new environment..."
  git add ./.github/workflows/push-"$branch".yaml terraform/environments/"$environment".tfvars
  git commit -m "Deploy $environment"
  git push origin "$branch"
  printf "\e[32mOK\e[0m\n"
fi