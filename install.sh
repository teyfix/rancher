#!/bin/bash
set -e

function die() {
  echo "$1"
  exit 1
}

function hint() {
  echo "  $@"
}

function prompt() {
  local input
  local prompt="$1"
  local varname="$2"
  local default="$3"

  new_line

  while [ -z "$input" ]; do
    if [ -n "$default" ]; then
      read -p "$prompt [$default]: " input
    else
      read -p "$prompt: " input
    fi

    if [ -z "$input" ]; then
      input="$default"
    fi

    if [ -z "$input" ]; then
      echo "Error: $varname is required (CTRL+C to exit)"
    else
      break
    fi
  done

  hint "\"$varname\" will be set to \"$input\""
  eval export $varname="${input:-$default}"
}

function install_deps() {
  local deps=(
    "curl"
  )

  sudo apt-get update

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      echo "This script requires \"$dep\" to be installed, the dependency will be installed now."
      sudo apt-get install -y "$dep"
    fi
  done
}

function get_public_ip() {
  local public_ip
  local public_ip_providers=(
    "https://ident.me"
    "https://ifconfig.me"
    "https://ifconfig.co"
    "https://ifconfig.io"
    "https://icanhazip.com"
    "https://ipinfo.io/ip"
    "https://ipecho.net/plain"
    "https://bot.whatismyipaddress.com"
  )

  for provider in "${public_ip_providers[@]}"; do
    public_ip=$(curl -s "$provider" 2>/dev/null || true)

    if [ -n "$public_ip" ]; then
      echo "$public_ip"
      return
    fi
  done
}

function lower_first() {
  local string="$1"

  echo "$string" | cut -c1 | tr '[:upper:]' '[:lower:]'
}

function new_line() {
  echo
}

function confirm() {
  local message="$1"
  local default="$2"
  local confirm="$default"

  local yes
  local no

  if [ "$default" == "y" ]; then
    yes="Y"
    no="n"
  else
    yes="y"
    no="N"
  fi

  new_line
  read -p "$message [$yes/$no]: " confirm

  confirm="$(echo "$confirm" | cut -c1 | tr '[:upper:]' '[:lower:]')"

  if [ -z "$confirm" ]; then
    confirm="$default"
  fi

  if [ "$confirm" != "y" ]; then
    die "Aborted"
  fi

  new_line
}

function main() {
  # Setup environment
  local PROFILE_FILE="$HOME/.$(basename "$SHELL")rc"

  # Setup default values
  local DEFAULT_K3S_VERSION="v1.28.5+k3s1"
  local DEFAULT_RANCHER_REPO="rancher-latest"
  local DEFAULT_RANCHER_NAMESPACE="cattle-system"
  local DEFAULT_RANCHER_PASSWORD="$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 | tr -d '/+' | cut -c1-32)"

  local confirm

  echo "This script will perform the following actions:"

  hint "Install required packages for this script to work."
  hint "Get your public IP address to inform about the DNS A record."
  hint "Update shell profile to include k3s and Helm aliases."
  hint "Install k3s and Helm."

  confirm "Do you want to continue?" "y"

  # Prompt for user input
  echo "Setup Rancher on k3s"

  hint "Rancher UI will use cert-manager to generate SSL certificates with Let's Encrypt."
  hint "Let's Encrypt requires an e-mail to be used as a contact in case of issues."
  hint "Please provide an e-mail address to be used by Let's Encrypt."

  prompt "E-mail" "LETSENCRYPT_EMAIL"

  # Prompt k3s version
  prompt "K3S version" "K3S_VERSION" "$DEFAULT_K3S_VERSION"

  # Rancher settings
  new_line
  echo "Getting public IP address..."

  local public_ip="$(get_public_ip)"

  hint "Please provide an FQDN that will be used to access the Rancher UI."
  hint "Rancher UI will be accessible within this domain."
  hint "You must setup an A record that points to \"$public_ip\" for this domain."

  prompt "Rancher hostname" "RANCHER_HOSTNAME"
  prompt "Rancher namespace" "RANCHER_NAMESPACE" "$DEFAULT_RANCHER_NAMESPACE"
  prompt "Rancher Helm repository" "RANCHER_REPO" "$DEFAULT_RANCHER_REPO"
  prompt "Rancher password" "RANCHER_PASSWORD" "$DEFAULT_RANCHER_PASSWORD"

  # Propmt to user for confirmation
  echo "Please confirm the following settings:"

  hint "- Email: $LETSENCRYPT_EMAIL"
  hint "- K3s Version: $K3S_VERSION"
  hint "- Rancher Helm Repository: $RANCHER_REPO"
  hint "- Rancher Namespace: $RANCHER_NAMESPACE"
  hint "- Rancher Hostname: $RANCHER_HOSTNAME"
  hint "- Rancher Password: $RANCHER_PASSWORD"

  confirm "Do you want to continue?" "y"

  cat <<EOF >>"$PROFILE_FILE"
export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
alias helm="sudo helm --kubeconfig /etc/rancher/k3s/k3s.yaml"
alias kubectl="sudo kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml"
EOF

  source "$PROFILE_FILE"

  # Install k3s
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" sh -

  # Install Helm
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

  # Install required Helm repositories for Rancher and Cert-Manager
  helm repo add jetstack https://charts.jetstack.io
  helm repo add "$RANCHER_REPO" https://releases.rancher.com/server-charts/latest
  helm repo update

  # Install Cert-Manager CRDs (Required for cert-manager to work)
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.3/cert-manager.crds.yaml

  # Install Cert-Manager
  helm install cert-manager jetstack/cert-manager \
    --version v1.11.3 \
    --namespace cert-manager \
    --create-namespace

  kubectl create namespace "$RANCHER_NAMESPACE"

  # Install certificate authority
  cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-rancher
  namespace: $RANCHER_NAMESPACE
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-rancher
    solvers:
      - http01:
          ingress:
            class: nginx
EOF

  helm install rancher "$RANCHER_REPO/rancher" --namespace "$RANCHER_NAMESPACE" --set bootstrapPassword="$RANCHER_PASSWORD" --values - <<EOF
hostname: $RANCHER_HOSTNAME
ingress:
  tls:
    source: letsEncrypt
    extraAnnotations:
      cert-manager.io/issuer: "letsencrypt-rancher"
letsEncrypt:
  email: $LETSENCRYPT_EMAIL
  environment: production
EOF

  new_line

  echo "Script successfully installed Rancher on k3s"
  echo "Rancher UI will be available at https://$RANCHER_HOSTNAME"
  echo "Rancher may take a few minutes to be available, please wait for the deployment to finish."
  echo "You will use \"$RANCHER_PASSWORD\" to login to Rancher UI."
}

main
