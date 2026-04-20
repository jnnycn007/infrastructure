# cnx-kube1

## Overview

This directory contains the Terraform manifests that define the resources for
the production CI Kubernetes cluster hosted by Centrinix.

The resources defined here are deployed to the `kube1` cluster of the Centrinix
Rancher Server.

## Deployment

### Overview

Deployment process must be executed locally using the Terraform cloud state
backend, which is managed in the `cnx-kube1` workspace in the Terraform cloud.

All secrets used during the deployment process are stored in the
`zephyr-secrets` application in the HCP Vault Secrets.

### Host Requirements

The deployment host must have Terraform, Vault (`vlt`) and kubectl installed.

In addition, the deployment host must have access to the Zephyr Centrinix internal
networks, which requires a special VPN connection, for connecting to the Rancher
Kubernetes cluster endpoints.

### Initial Deployment

It is recommended to execute the cluster deployment process in multiple partial
steps to ensure that each component layer is fully deployed before proceeding to
deploy the next layer.

1. Deploy Actions Runner Controller:

```
terraform apply -target=helm_release.arc
```

2. Deploy rest of the resources:

```
terraform apply
```

## Operations

### Runner Scale Set Management

To create and activate all runner scale sets in the cnx-kube1 deployment:

```
terraform apply \
    -target=helm_release.zephyr_runner_v2_linux_arm64_4xlarge_cnx
```

To destroy and deactivate all runner scale sets in the cnx-kube1 deployment:

```
terraform destroy \
    -target=helm_release.zephyr_runner_v2_linux_arm64_4xlarge_cnx
```
