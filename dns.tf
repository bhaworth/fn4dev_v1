resource "oci_dns_rrset" "lb_a_record" {
  count = var.create_dns ? 1 : 0

  domain          = "${local.Fn4_env_name}.oci.fn4dev.ml"
  rtype           = "A"
  zone_name_or_id = local.Fn4dev_ml_dns_zone_id
  #compartment_id = local.Fn4dev_ml_dns_comp_id
  items {
    domain = "${local.Fn4_env_name}.oci.fn4dev.ml"
    rtype  = "A"
    rdata  = local.Fn4_lb_public_ip
    ttl    = 30

  }

}

resource "oci_dns_rrset" "bastion_a_record" {
  count = var.create_dns ? 1 : 0

  domain          = "bastion.${local.Fn4_env_name}.oci.fn4dev.ml"
  rtype           = "A"
  zone_name_or_id = local.Fn4dev_ml_dns_zone_id
  #compartment_id = local.Fn4dev_ml_dns_comp_id
  items {
    domain = "bastion.${local.Fn4_env_name}.oci.fn4dev.ml"
    rtype  = "A"
    rdata  = local.Fn4Bastion_public_ip
    ttl    = 30

  }

}
