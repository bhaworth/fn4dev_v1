# Network Security Group for App/DB Nodes

resource "oci_core_network_security_group" "appdb_nsg" {
  display_name   = "${local.Fn4_env_name}-appdb-nsg"
  vcn_id         = local.Fn4_vcn_id
  compartment_id = local.Fn4_cid
}

locals {
  appdb_nsg_id = oci_core_network_security_group.appdb_nsg.id
}
