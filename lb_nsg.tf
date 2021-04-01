# Network Security Group for the Load Balancer

# Allow port 5025 in to the load balancer

resource "oci_core_network_security_group" "lb_nsg" {
  display_name   = "${local.Fn4_env_name}-lb-nsg"
  vcn_id         = local.Fn4_vcn_id
  compartment_id = local.Fn4_cid
}

locals {
  lb_nsg_id = oci_core_network_security_group.lb_nsg.id
}

resource "oci_core_network_security_group_security_rule" "lb-nsg-rule1" {
  network_security_group_id = local.lb_nsg_id

  direction   = "INGRESS"
  protocol    = "6"
  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  stateless   = false
  description = "TCP/5025 (HTTP) for Inbound HTTP"
  tcp_options {
    destination_port_range {
      min = "5025"
      max = "5025"
    }
  }
}
