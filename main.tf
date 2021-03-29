# ------ Provider
provider "oci" {
  region = var.region
}

locals {
  Fn4_ssh_key               = var.ssh_pub_key
  Fn4_bastion_shape         = var.bastion_shape
  Fn4_bastion_image         = var.bastion_image
  Fn4_env_name              = var.name_prefix == "" ? "${var.env_name}-${local.Fn4_deploy_id}" : "${var.name_prefix}-${var.env_name}-${local.Fn4_deploy_id}"
  is_flexible_bastion_shape = contains(local.compute_flexible_shapes, local.Fn4_bastion_shape)
}

# ------ Create Instance
resource "oci_core_instance" "Fn4Bastion" {
  # Required
  compartment_id = local.Fn4_cid
  shape          = local.Fn4_bastion_shape
  # Optional
  display_name        = "${local.Fn4_env_name}-bastion"
  availability_domain = local.Fn4_ad
  agent_config {
    # Optional
  }
  create_vnic_details {
    # Required
    subnet_id = local.Pubsn001_id
    # Optional
    assign_public_ip       = true
    display_name           = "${local.Fn4_env_name}-bastion vnic 00"
    hostname_label         = "${local.Fn4_env_name}-bastion"
    skip_source_dest_check = "false"
  }
  metadata = {
    ssh_authorized_keys = local.Fn4_ssh_key
    user_data           = data.template_cloudinit_config.bastion.rendered
  }

  extended_metadata = {
    tenancy_id    = var.tenancy_ocid
    deployment_id = local.Fn4_deploy_id
  }

  dynamic "shape_config" {
    for_each = local.is_flexible_bastion_shape ? [1] : []
    content {
      ocpus         = var.bastion_ocpus
      memory_in_gbs = var.bastion_ram
    }
  }

  source_details {
    source_id   = local.Fn4_bastion_image
    source_type = "image"
    # Optional
    boot_volume_size_in_gbs = var.bastion_boot_size
    #        kms_key_id              = 
  }
  preserve_boot_volume = false
}

locals {
  Fn4Bastion_id         = oci_core_instance.Fn4Bastion.id
  Fn4Bastion_public_ip  = oci_core_instance.Fn4Bastion.public_ip
  Fn4Bastion_private_ip = oci_core_instance.Fn4Bastion.private_ip
  Fn4_bastion_connect   = var.create_dns ? "bastion.${local.Fn4_env_name}.oci.fn4dev.ml" : local.Fn4Bastion_public_ip
}

output "Fn4_bastion" {
  value = local.Fn4_bastion_connect
}

output "Fn4_deploy_id" {
  value = local.Fn4_deploy_id
}
