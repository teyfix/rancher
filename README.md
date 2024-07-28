# Rancher on k3s automated script

This script will setup a k3s cluster that will have Rancher UI.

## Install

### Install with cURL

```sh
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/teyfix/rancher/4a7754afb3e4ca4049de65a1e20aef0dd7916358/install.sh)"
```

### Install with wget

```sh
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/teyfix/rancher/4a7754afb3e4ca4049de65a1e20aef0dd7916358/install.sh)"
```
