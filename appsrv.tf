locals {
  Fn4_appsrv_shape         = var.appsrv_shape
  Fn4_appsrv_image         = var.appsrv_image
  is_flexible_appsrv_shape = contains(local.compute_flexible_shapes, local.Fn4_appsrv_shape)
}


# ------ Create App Srv Instance
resource "oci_core_instance" "Fn4App" {
  count = var.appsrv_count
  # Required
  compartment_id = local.Fn4_cid
  shape          = local.Fn4_appsrv_shape
  # Optional
  display_name        = "${local.Fn4_env_name}-app-${count.index + 1}"
  # If count < 3 then fn4_ad else choose another based on calculation based on count

  availability_domain = local.ad_random_seq[count.index % length(local.ad_random_seq)]

  # Set fault domain to be a calculation from count

  fault_domain = "FAULT-DOMAIN-${count.index + 1}"
  create_vnic_details {
    # Required
    subnet_id = local.Privsn001_id
    # Optional
    assign_public_ip       = false
    display_name           = "${local.Fn4_env_name}-app-${count.index + 1} vnic 00"
    hostname_label         = "${local.Fn4_env_name}-app-${count.index + 1}"
    skip_source_dest_check = "false"
    nsg_ids                = [local.app_nsg_id]
  }
  metadata = {
    ssh_authorized_keys = local.Fn4_ssh_key
    user_data           = data.template_cloudinit_config.appsrv.rendered
  }

  dynamic "shape_config" {
    for_each = local.is_flexible_appsrv_shape ? [1] : []
    content {
      ocpus         = var.appsrv_ocpus
      memory_in_gbs = var.appsrv_ram
    }
  }
  source_details {
    # Required
    source_id   = local.Fn4_appsrv_image
    source_type = "image"
    # Optional
    boot_volume_size_in_gbs = var.appsrv_boot_size
    #        kms_key_id              = 
  }
  preserve_boot_volume = false
}

locals {
  Fn4App_ids         = oci_core_instance.Fn4App.*.id
  Fn4App_private_ips = oci_core_instance.Fn4App.*.private_ip
}

output "Fn4App_DB_SrvPrivateIP" {
  value = local.Fn4App_private_ips
}

output "appsrv_ids" { value = local.Fn4App_ids }

