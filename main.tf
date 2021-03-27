# ------ Provider
provider "oci" {
  region = var.region
}

locals {
  Fn4_ssh_key                = var.ssh_pub_key
  Fn4_bastion_shape          = var.bastion_shape
  Fn4_bastion_image          = var.bastion_image
  Fn4_headnode_shape         = var.headnode_shape
  Fn4_headnode_image         = var.headnode_image
  Fn4_env_name               = var.name_prefix == "" ? "${var.env_name}-${local.Fn4_deploy_id}" : "${var.name_prefix}-${var.env_name}-${local.Fn4_deploy_id}"
  is_flexible_bastion_shape  = contains(local.compute_flexible_shapes, local.Fn4_bastion_shape)
  is_flexible_headnode_shape = contains(local.compute_flexible_shapes, local.Fn4_headnode_shape)
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

# ------ Create Head Node Instance
resource "oci_core_instance" "Fn4Headnode" {
  # Required
  compartment_id = local.Fn4_cid
  shape          = local.Fn4_headnode_shape
  # Optional
  display_name        = "${local.Fn4_env_name}-headnode"
  availability_domain = local.Fn4_ad
  create_vnic_details {
    # Required
    subnet_id = local.Privsn001_id
    # Optional
    assign_public_ip       = false
    display_name           = "${local.Fn4_env_name}-headnode vnic 00"
    hostname_label         = "${local.Fn4_env_name}-headnode"
    skip_source_dest_check = "false"
    nsg_ids                = [local.hn_nsg_id]
  }
  metadata = {
    ssh_authorized_keys = local.Fn4_ssh_key
    user_data           = data.template_cloudinit_config.headnode.rendered
  }
  extended_metadata = {
    tenancy_id    = var.tenancy_ocid
    deployment_id = local.Fn4_deploy_id
    subnet_id     = local.Privsn001_id
  }

  dynamic "shape_config" {
    for_each = local.is_flexible_headnode_shape ? [1] : []
    content {
      ocpus         = var.headnode_ocpus
      memory_in_gbs = var.headnode_ram
    }
  }
  source_details {
    # Required
    source_id   = local.Fn4_headnode_image
    source_type = "image"
    # Optional
    boot_volume_size_in_gbs = var.hn_boot_size
    #        kms_key_id              = 
  }
  preserve_boot_volume = false
}

locals {
  Fn4Headnode_id         = oci_core_instance.Fn4Headnode.id
  Fn4Headnode_public_ip  = oci_core_instance.Fn4Headnode.public_ip
  Fn4Headnode_private_ip = oci_core_instance.Fn4Headnode.private_ip
}

output "Fn4App_DB_SrvPrivateIP" {
  value = local.Fn4Headnode_private_ip
}

# ------ Create Block Storage Volume
resource "oci_core_volume" "Data" {
  # Required
  compartment_id      = local.Fn4_cid
  availability_domain = local.Fn4_ad
  # Optional
  display_name = "${local.Fn4_env_name}-data"
  size_in_gbs  = var.hn_data_size
  vpus_per_gb  = "10"
}

locals {
  Data_id = oci_core_volume.Data.id
}

# ------ Create Block Storage Volume
resource "oci_core_volume" "Work" {
  # Required
  compartment_id      = local.Fn4_cid
  availability_domain = local.Fn4_ad
  # Optional
  display_name = "${local.Fn4_env_name}-work"
  size_in_gbs  = var.hn_work_size
  vpus_per_gb  = "10"
}

locals {
  Work_id = oci_core_volume.Work.id
}

# ------ Create Block Storage Attachments
resource "oci_core_volume_attachment" "Fn4HeadnodeDataVolumeAttachment" {
  attachment_type                     = "paravirtualized"
  device                              = "/dev/oracleoci/oraclevdb"
  display_name                        = "${local.Fn4_env_name}-HeadnodeDataVolumeAttachment"
  instance_id                         = local.Fn4Headnode_id
  is_pv_encryption_in_transit_enabled = "false"
  is_read_only                        = "false"
  #is_shareable = <<Optional value not found in discovery>>
  #use_chap = <<Optional value not found in discovery>>
  volume_id = local.Data_id
}
resource "oci_core_volume_attachment" "Fn4HeadnodeWorkVolumeAttachment" {
  attachment_type                     = "paravirtualized"
  device                              = "/dev/oracleoci/oraclevdc"
  display_name                        = "${local.Fn4_env_name}-HeadnodeDataVolumeAttachment"
  instance_id                         = local.Fn4Headnode_id
  is_pv_encryption_in_transit_enabled = "false"
  is_read_only                        = "false"
  #is_shareable = <<Optional value not found in discovery>>
  #use_chap = <<Optional value not found in discovery>>
  volume_id = local.Work_id
}

output "Fn4_deploy_id" {
  value = local.Fn4_deploy_id
}
