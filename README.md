# Rancher on k3s Automated Script

This script automates the setup of a k3s cluster with the Rancher UI, including Let's Encrypt SSL for secure access. This can help you quickly create new clusters for testing, development, or learning purposes.

## Disclaimer

Although you can use this cluster for deploying real applications, please be aware that I am currently unaware of all potential caveats.

## Features

- Automated k3s Cluster Setup: Easily set up a lightweight Kubernetes cluster using k3s.
- Rancher UI: Deploy Rancher for simplified Kubernetes cluster management.
- Let's Encrypt SSL: Automatically configure SSL certificates for secure access to the Rancher UI.
- Public IP Detection: Automatically detect and use your VM's public IP for configuration of the DNS A record.
- User Prompts: Interactive script prompts to customize the setup according to your needs.

## Prerequisites

- Ubuntu or Debian-based system: The script is designed to work on these operating systems.
- sudo privileges: The script requires elevated privileges to install dependencies and configure the system.

## Installation

- You can install the script using either `curl` or `wget`.

### Install with cURL

To install and run the script using curl, execute the following command in your terminal:

```sh
sudo -E bash -c "$(curl -fsSL https://raw.githubusercontent.com/teyfix/rancher/9186c2431aedb81b58544293fb55978462429541/install.sh)"
```

### Install with wget

To install and run the script using wget, execute the following command in your terminal:

```sh
sudo -E bash -c "$(wget -qO- https://raw.githubusercontent.com/teyfix/rancher/9186c2431aedb81b58544293fb55978462429541/install.sh)"
```

## Post-Installation

- After running the script, your k3s cluster with Rancher UI will be set up. You can access the Rancher UI using the provided FQDN and manage your Kubernetes clusters easily.
- You don't have to SSH to machine after the Rancher UI is up. You can use the `kubectl` CLI provided by rancher to easily run commands.

## Future Improvements

- I am considering adding a cloud-config file to further automate the process, eliminating the need for SSH access to newly created machines.

## Feedback and Contributions

- I welcome any feedback and contributions to improve this script. Feel free to open an issue or submit a pull request on this GitHub repository.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
