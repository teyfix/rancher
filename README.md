# Rancher on k3s automated script

This script will setup a k3s cluster that will have Rancher UI.

## Install

### Install with cURL

```sh
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/teyfix/rancher/496feed938870065a3bc5fee62650c02ca6e62ab/install.sh)"
```

### Install with wget

```sh
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/teyfix/rancher/496feed938870065a3bc5fee62650c02ca6e62ab/install.sh)"
```
