# Network Security Group for DB Nodes

resource "oci_core_network_security_group" "db_nsg" {
  display_name   = "${local.Fn4_env_name}-db-nsg"
  vcn_id         = local.Fn4_vcn_id
  compartment_id = local.Fn4_cid
}

resource "oci_core_network_security_group_security_rule" "db-nsg-rule1" {
  network_security_group_id = local.db_nsg_id

  direction   = "INGRESS"
  protocol    = "all"
  source      = local.app_nsg_id
  source_type = "NETWORK_SECURITY_GROUP"
  stateless   = false
  description = "Allow all ports from App to DB servers - FOR TESTING ONLY"
}

locals {
  db_nsg_id = oci_core_network_security_group.db_nsg.id
}
