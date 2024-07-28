# Rancher on k3s automated script

This script will setup a k3s cluster that will have Rancher UI.

## Install

### Install with cURL

```sh
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/teyfix/rancher/b79fbabe6054503188424d2c2a0fd35f60b0e7db/install.sh)"
```

### Install with wget

```sh
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/teyfix/rancher/b79fbabe6054503188424d2c2a0fd35f60b0e7db/install.sh)"
```
