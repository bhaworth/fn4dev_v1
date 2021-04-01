# Network Security Group for App Nodes

resource "oci_core_network_security_group" "app_nsg" {
  display_name   = "${local.Fn4_env_name}-app-nsg"
  vcn_id         = local.Fn4_vcn_id
  compartment_id = local.Fn4_cid
}

resource "oci_core_network_security_group_security_rule" "app-nsg-rule1" {
  network_security_group_id = local.app_nsg_id

  direction   = "INGRESS"
  protocol    = "6"
  source      = local.lb_nsg_id
  source_type = "NETWORK_SECURITY_GROUP"
  stateless   = false
  description = "TCP/${local.Fn4_lb_port} (HTTPS) for Web Service from Load Balancer"
  tcp_options {
    destination_port_range {
      min = local.Fn4_lb_port
      max = local.Fn4_lb_port
    }
  }
}

locals {
  app_nsg_id = oci_core_network_security_group.app_nsg.id
}
