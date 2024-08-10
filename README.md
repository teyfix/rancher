# Rancher on k3s Automated Script

This script automates the setup of a k3s cluster with the Rancher UI, including
Let's Encrypt SSL for secure access. This can help you quickly create new
clusters for testing, development, or learning purposes.

## Disclaimer

Although you can use this cluster for deploying real applications, please be
aware that I am currently unaware of all potential caveats.

## Features

- **Automated k3s Cluster Setup**: Easily set up a lightweight Kubernetes
  cluster using k3s.
- **Rancher UI**: Deploy Rancher for simplified Kubernetes cluster management.
- **High availability**: Support highly available local Rancher cluster with
  embedded `etcd`.
- **Let's Encrypt SSL**: Automatically configure SSL certificates for secure
  access to the Rancher UI.
- **Public IP Detection**: Automatically detect and use your VM's public IP for
  configuration of the DNS A record.
- **Environment Variables Exposure**: Set environment variables to bypass
  interactive prompts and automate the setup process.
  - **K3S_TOKEN** and **K3S_URL**: Use these to join an existing cluster.
  - **LETSENCRYPT_EMAIL** and **RANCHER_HOSTNAME**: Use these for Rancher
    installation.
  - Additional environment variables can be set to override defaults or
    user-provided inputs.
- **User Prompts**: Interactive script prompts to customize the setup according
  to your needs.

## Prerequisites

- **Ubuntu or Debian-based system**: The script is designed to work on these
  operating systems.
- **sudo privileges**: The script requires elevated privileges to install
  dependencies and configure the system.

## Installation

You can install the script using either `curl` or `wget`.

### Install with cURL

To install and run the script using curl, execute the following command in your
terminal:

```sh
sudo -E bash -c "$(curl -fsSL https://raw.githubusercontent.com/teyfix/rancher/265619e1985165ecd5baf86b051ad3ceae04f4d1/install.sh)"
```

### Install with wget

To install and run the script using wget, execute the following command in your
terminal:

```sh
sudo -E bash -c "$(wget -qO- https://raw.githubusercontent.com/teyfix/rancher/265619e1985165ecd5baf86b051ad3ceae04f4d1/install.sh)"
```

## Environment Variables

The script supports the following environment variables to customize the
installation:

- `K3S_URL`: URL of the existing k3s cluster to join.
  - `K3S_URL` will be provided to you after the first installation.
  - You can also use the master node's public/private IP.
  - You must ensure new nodes can access to the K3S API endpoint. _(Default is
    https://<master_hostname>:6443)_
- `K3S_TOKEN`: Token to join an existing k3s cluster.
  - `K3S_TOKEN` will be generated and printed to you after the first
    installation if you don't provide one.
- `LETSENCRYPT_EMAIL`: Email for Let's Encrypt SSL certificate registration.
- `RANCHER_HOSTNAME`: FQDN to access the Rancher UI.
- `RANCHER_NAMESPACE`: Namespace for Rancher installation (default is
  `cattle-system`).
- `RANCHER_REPO`: Rancher Helm repository (default is `rancher-stable`).
- `RANCHER_PASSWORD`: Password for Rancher UI access.

Also any other k3s environment variables are supported by k3s itself. Checkout
[installation](https://docs.k3s.io/installation/configuration) and
[advanced configuration](https://docs.k3s.io/advanced) documentations
respectively.

### Example Usage

To automate the setup using environment variables, export them before running
the script:

```sh
export K3S_TOKEN=<your_k3s_token>
export K3S_URL=https://<master_hostname>:6443
export LETSENCRYPT_EMAIL=<your_email>
export RANCHER_HOSTNAME=<your_rancher_hostname>
```

## Post-Installation

- After running the script, your k3s cluster with Rancher UI will be set up. You
  can access the Rancher UI using the provided FQDN and manage your Kubernetes
  clusters easily.
- You don't have to SSH to the machine after the Rancher UI is up. You can use
  the `kubectl` CLI provided by Rancher to easily run commands.

## Future Improvements

- I am considering adding Terraform scripts for various cloud providers.

## Feedback and Contributions

I welcome any feedback and contributions to improve this script. Feel free to
open an issue or submit a pull request on this GitHub repository.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file
for details.
