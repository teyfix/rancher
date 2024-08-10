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
  local should_seed="$4"

  if [ -n "${!varname}" ]; then
    return
  fi

  if [ "$should_seed" = "true" ]; then
    eval export $varname="$default"
    hint "\"$varname\" will be set to \"$default\""
    return
  fi

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

  apt-get update

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      echo "This script requires \"$dep\" to be installed, the dependency will be installed now."
      apt-get install -y "$dep"
    fi
  done
}

function get_public_ip() {
  local public_ip
  local public_ip_providers=(
    "https://ident.me"
    "https://icanhazip.com"
    "https://ipinfo.io/ip"
    "https://ipecho.net/plain"
  )

  echo "Getting public IP address..."

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

  if [ "$default" = "y" ]; then
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
  local DEFAULT_RANCHER_REPO="rancher-stable"
  local DEFAULT_RANCHER_NAMESPACE="cattle-system"
  local DEFAULT_RANCHER_PASSWORD="$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 | tr -d '/+' | cut -c1-32)"

  local confirm
  local ci="false"
  local join="false"

  if [[ -n "$K3S_TOKEN" && -n "$K3S_URL" ]]; then
    echo "Your environment exposed K3S_TOKEN and K3S_URL, using them to join the cluster."

    ci="true"
    join="true"

    local master_hostname

    if [[ "$K3S_URL" == *"@"* ]]; then
      master_hostname="$(echo "$K3S_URL" | awk -F[:/@] '{print $6}')"
    else
      master_hostname="$(echo "$K3S_URL" | awk -F[:/] '{print $4}')"
    fi

    export RANCHER_HOSTNAME="$master_hostname"
  fi

  if [[ -n "$LETSENCRYPT_EMAIL" && -n "$RANCHER_HOSTNAME" ]]; then
    echo "Your environment exposed LETSENCRYPT_EMAIL and RANCHER_HOSTNAME, using them to install Rancher."
    echo "If you set any other environment variables, they will be used as well."
    echo "Otherwise, default values will be used."

    ci="true"
  fi

  if [ "$ci" = 'false' ]; then
    echo "This script will perform the following actions:"

    hint "Install required packages for this script to work."
    hint "Get your public IP address to inform about the DNS A record."
    hint "Update shell profile to include k3s and Helm aliases."
    hint "Install k3s and Helm."

    confirm "Do you want to continue?" "y"
    new_line
  fi

  install_deps

  eval $(echo "export KUBECONFIG='/etc/rancher/k3s/k3s.yaml'" | tee -a "$PROFILE_FILE")

  if [ -z "$LETSENCRYPT_EMAIL" ]; then
    hint "Rancher UI will use cert-manager to generate SSL certificates with Let's Encrypt."
    hint "Let's Encrypt requires an e-mail to be used as a contact in case of issues."
    hint "Please provide an e-mail address to be used by Let's Encrypt."
  fi

  if [ "$ci" = 'false' ]; then
    prompt "E-mail" "LETSENCRYPT_EMAIL"
  fi

  # Prompt k3s version
  prompt "K3S version" "K3S_VERSION" "$DEFAULT_K3S_VERSION" "$ci"

  local public_ip="$(get_public_ip)"

  if [ -z "$RANCHER_HOSTNAME" ]; then
    hint "Please provide an FQDN that will be used to access the Rancher UI."
    hint "Rancher UI will be accessible within this domain."
    hint "You must setup an A record that points to \"$public_ip\" for this domain."
  fi

  prompt "Rancher hostname" "RANCHER_HOSTNAME"
  prompt "Rancher namespace" "RANCHER_NAMESPACE" "$DEFAULT_RANCHER_NAMESPACE" "$ci"
  prompt "Rancher Helm repository" "RANCHER_REPO" "$DEFAULT_RANCHER_REPO" "$ci"
  prompt "Rancher password" "RANCHER_PASSWORD" "$DEFAULT_RANCHER_PASSWORD" "$ci"

  local endpoints="$(echo "$public_ip $RANCHER_HOSTNAME $(hostname -I) $(hostname -A)" | xargs | tr ' ' ',')"
  local install_k3s_cmd="curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='$K3S_VERSION' sh -s - server --tls-san='$endpoints'"

  if [ "$join" = 'true' ]; then
    eval "$install_k3s_cmd"
    return 0
  fi

  hint "- Email: $LETSENCRYPT_EMAIL"
  hint "- K3s Version: $K3S_VERSION"
  hint "- Rancher Helm Repository: $RANCHER_REPO"
  hint "- Rancher Namespace: $RANCHER_NAMESPACE"
  hint "- Rancher Hostname: $RANCHER_HOSTNAME"
  hint "- Rancher Password: $RANCHER_PASSWORD"

  new_line

  echo "K3S Server will be accessible by these endpoints:"
  echo "$endpoints" | xargs -d, -n1 echo '  -'

  if [ "$ci" = 'false' ]; then
    confirm "Do you want to continue?" "y"
  fi

  echo "Installing k3s with version $K3S_VERSION"
  eval "$install_k3s_cmd --cluster-init"

  # Install Helm
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

  local RANCHER_REPO_BRANCH="$(echo "$RANCHER_REPO" | awk -F- '{print $2}')"

  # Install required Helm repositories for Rancher and Cert-Manager
  helm repo add jetstack https://charts.jetstack.io
  helm repo add "$RANCHER_REPO" "https://releases.rancher.com/server-charts/$RANCHER_REPO_BRANCH"
  helm repo update

  # Install Cert-Manager CRDs (Required for cert-manager to work)
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.3/cert-manager.crds.yaml

  # Install Cert-Manager
  helm install cert-manager jetstack/cert-manager --version v1.11.3 --namespace cert-manager --create-namespace

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

  local k3s_server_token="$(cat /var/lib/rancher/k3s/server/token)"

  new_line

  echo "Script successfully installed Rancher on k3s"
  echo "Rancher UI will be available at https://$RANCHER_HOSTNAME"
  echo "Rancher may take a few minutes to be available, please wait for the deployment to finish."
  echo "You will use \"$RANCHER_PASSWORD\" to login to Rancher UI."

  new_line

  local k3s_endpoint="$(echo "$endpoints" | xargs -n1 | grep -E '^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.|^192\.168\.' | head -n1)"

  if [ -z "$k3s_endpoint" ]; then
    k3s_endpoint="$public_ip"
  fi

  echo "You can also use this script to join new nodes to local cluster:"
  echo "curl -sfL https://get.k3s.io | sh -s - server --token='$k3s_server_token' --server https://$k3s_endpoint:6443"
}

# Check if user is root
if [ "$(id -u)" != "0" ]; then
  die "Error: This script must be run as root."
fi

main
