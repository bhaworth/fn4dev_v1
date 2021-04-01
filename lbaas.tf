resource "oci_network_load_balancer_network_load_balancer" "Fn4_netloadbalancer" {
  compartment_id = local.Fn4_cid

  display_name = "${local.Fn4_env_name}-nlb"

  is_private                     = "false"
  is_preserve_source_destination = "false"
  network_security_group_ids     = [local.lb_nsg_id]

  subnet_id = local.Pubsn001_id
}

locals {
  Fn4_lb_port      = var.nlb_port
  Fn4_lb_public_ip = lookup(oci_network_load_balancer_network_load_balancer.Fn4_netloadbalancer.ip_addresses[0], "ip_address")
  Fn4_lb_url       = var.create_dns ? "${local.Fn4_env_name}.oci.fn4dev.ml:${local.Fn4_lb_port}" : "${local.Fn4_lb_public_ip}:${local.Fn4_lb_port}"
}
output "Fn4_loadbalancer_url" {
  value = local.Fn4_lb_url
}
output "Fn4_loadbalancer_public_ip" {
  value = local.Fn4_lb_public_ip
}

locals { Fn4_lb_id = oci_network_load_balancer_network_load_balancer.Fn4_netloadbalancer.id }

resource "oci_network_load_balancer_backend_set" "be_set_1" {
  health_checker {
    interval_in_millis = "10000"
    protocol            = "TCP"
    request_data        = ""
    response_body_regex = ""
    response_data       = ""
    retries             = "3"
    timeout_in_millis = "3000"
  }
  is_preserve_source       = "true"
  name                     = "be-set-1"
  network_load_balancer_id = local.Fn4_lb_id
  policy                   = "FIVE_TUPLE"
}

resource "oci_network_load_balancer_listener" "listener_1" {
  default_backend_set_name = oci_network_load_balancer_backend_set.be_set_1.name
  name                     = "listener_1"
  network_load_balancer_id = local.Fn4_lb_id
  port                     = local.Fn4_lb_port
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend" "be_app" {
  count = var.appsrv_count
  backend_set_name         = oci_network_load_balancer_backend_set.be_set_1.name
  target_id                = local.Fn4App_ids[count.index]
  is_backup                = "false"
  is_drain                 = "false"
  is_offline               = "false"
  network_load_balancer_id = local.Fn4_lb_id
  port                     = local.Fn4_lb_port
  weight                   = "1"
}


