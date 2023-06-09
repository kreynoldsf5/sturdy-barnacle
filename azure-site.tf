resource "volterra_cloud_credentials" "azure" {
  name        = format("%s-cred", local.azure_name)
  description = format("Azure credential will be used to create site %s", local.azure_name)
  namespace   = "system"

  azure_client_secret {
    client_id       = var.azure_client_id
    subscription_id = var.azure_subscription_id
    tenant_id       = var.azure_tenant_id
    client_secret {
      clear_secret_info {
        url = "string:///${base64encode(var.azure_client_secret)}"
      }
    }
  }
}

resource "volterra_azure_vnet_site" "this" {
  name         = local.azure_name
  namespace    = "system"
  azure_region = var.azure_region

  azure_cred {
    name      = volterra_cloud_credentials.azure.name
    namespace = "system"
  }

  resource_group = var.azure_resource_group
  vnet {
    new_vnet {
      name         = local.azure_name
      primary_ipv4 = var.azure_vnet_cidr
    }
  }
  machine_type = var.azure_machine_type
  disk_size    = var.site_disk_size

  ingress_egress_gw {
    azure_certified_hw = "azure-byol-multi-nic-voltmesh"
    az_nodes {
      azure_az  = var.azure_az
      disk_size = var.site_disk_size
      inside_subnet {
        subnet_param {
          ipv4 = lookup(var.azure_subnet_ce_cidr, "inside", "")
        }
      }
      outside_subnet {
        subnet_param {
          ipv4 = lookup(var.azure_subnet_ce_cidr, "outside", "")
        }
      }
    }
    inside_static_routes {
      static_route_list {
        simple_static_route = var.azure_client_vnet_cidr
      }
    }
    global_network_list {
      global_network_connections {
        sli_to_global_dr {
          global_vn {
            name      = volterra_virtual_network.global_vn.name
            namespace = "system"
          }
        }
      }
    }
    no_global_network        = false
    no_outside_static_routes = true
    no_inside_static_routes  = false
    no_network_policy        = true
    no_forward_proxy         = false
    forward_proxy_allow_all  = true
  }
  logs_streaming_disabled = true
  ssh_key                 = var.ssh_public_key
  lifecycle {
    ignore_changes = [labels]
  }
}

resource "null_resource" "wait_for_azure_mns" {
  triggers = {
    depends = volterra_azure_vnet_site.this.id
  }
}

resource "volterra_tf_params_action" "apply_az_vnet" {
  depends_on       = [null_resource.wait_for_azure_mns]
  site_name        = local.azure_name
  site_kind        = "azure_vnet_site"
  action           = "apply"
  wait_for_action  = true
  ignore_on_update = true
}