terraform {
  required_version = ">= 0.15"
  required_providers {
    volterra = {
      source = "volterraedge/volterra"
      version = "0.11.7"
    }
  }
}

provider "volterra" {
  api_p12_file = "${path.root}/${var.api_p12_file}"
  url          = var.api_url
}

locals {
  azure_name         = format("%s-azure", var.mcn_name)
  namespace          = var.volterra_namespace_exists ? join("", data.volterra_namespace.this.*.name) : join("", volterra_namespace.this.*.name)
  azure_peer_subnets = [cidrsubnet(var.azure_client_vnet_cidr, 1, 0), cidrsubnet(var.azure_client_vnet_cidr, 1, 1)]
}

data "volterra_namespace" "this" {
  count = var.volterra_namespace_exists ? 1 : 0
  name  = var.volterra_namespace
}