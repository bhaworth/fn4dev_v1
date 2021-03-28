# ------ Provider
provider "oci" {
  region = var.region
}

locals {
  Fn4_ssh_key                = var.ssh_pub_key
  Fn4_bastion_shape          = var.bastion_shape
  Fn4_bastion_image          = var.bastion_image
  Fn4_appdbsrv_shape         = var.appdbsrv_shape
  Fn4_appdbsrv_image         = var.appdbsrv_image
  Fn4_env_name               = var.name_prefix == "" ? "${var.env_name}-${local.Fn4_deploy_id}" : "${var.name_prefix}-${var.env_name}-${local.Fn4_deploy_id}"
  is_flexible_bastion_shape  = contains(local.compute_flexible_shapes, local.Fn4_bastion_shape)
  is_flexible_appdbsrv_shape = contains(local.compute_flexible_shapes, local.Fn4_appdbsrv_shape)
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

# ------ Create App DB Srv Instance
resource "oci_core_instance" "Fn4AppDb" {
  count = var.appdbsrv_count
  # Required
  compartment_id = local.Fn4_cid
  shape          = local.Fn4_appdbsrv_shape
  # Optional
  display_name        = "${local.Fn4_env_name}-appdb-${count.index + 1}"
  availability_domain = local.Fn4_ad
  create_vnic_details {
    # Required
    subnet_id = local.Privsn001_id
    # Optional
    assign_public_ip       = false
    display_name           = "${local.Fn4_env_name}-appdb-${count.index + 1} vnic 00"
    hostname_label         = "${local.Fn4_env_name}-appdb-${count.index + 1}"
    skip_source_dest_check = "false"
    nsg_ids                = [local.appdb_nsg_id]
  }
  metadata = {
    ssh_authorized_keys = local.Fn4_ssh_key
    user_data           = data.template_cloudinit_config.appdbsrv.rendered
  }
  extended_metadata = {
    tenancy_id    = var.tenancy_ocid
    deployment_id = local.Fn4_deploy_id
    subnet_id     = local.Privsn001_id
  }

  dynamic "shape_config" {
    for_each = local.is_flexible_appdbsrv_shape ? [1] : []
    content {
      ocpus         = var.appdbsrv_ocpus
      memory_in_gbs = var.appdbsrv_ram
    }
  }
  source_details {
    # Required
    source_id   = local.Fn4_appdbsrv_image
    source_type = "image"
    # Optional
    boot_volume_size_in_gbs = var.appdb_boot_size
    #        kms_key_id              = 
  }
  preserve_boot_volume = false
}

locals {
  Fn4AppDb_ids         = oci_core_instance.Fn4AppDb.*.id
  Fn4AppDb_private_ips = oci_core_instance.Fn4AppDb.*.private_ip
}

output "Fn4App_DB_SrvPrivateIP" {
  value = [local.Fn4AppDb_private_ips]
}

# ------ Create Block Storage Volume for Backup
resource "oci_core_volume" "Backup" {
  count = var.appdbsrv_count
  # Required
  compartment_id      = local.Fn4_cid
  availability_domain = local.Fn4_ad
  # Optional
  display_name = "${local.Fn4_env_name}-backup-${count.index + 1}"
  size_in_gbs  = var.appdb_backup_size
  vpus_per_gb  = "10"
}

locals {
  Backup_ids = oci_core_volume.Backup.*.id
}

# ------ Create Block Storage Attachments
resource "oci_core_volume_attachment" "Fn4AppDbBackupVolumeAttachment" {
  count                               = var.appdbsrv_count
  attachment_type                     = "paravirtualized"
  device                              = "/dev/oracleoci/oraclevdb"
  display_name                        = "${local.Fn4_env_name}-AppDb_Backup-VolumeAttachment-${count.index + 1}"
  instance_id                         = oci_core_instance.Fn4AppDb[count.index].id
  is_pv_encryption_in_transit_enabled = "false"
  is_read_only                        = "false"
  #is_shareable = <<Optional value not found in discovery>>
  #use_chap = <<Optional value not found in discovery>>
  volume_id = oci_core_volume.Backup[count.index].id
}

output "Fn4_deploy_id" {
  value = local.Fn4_deploy_id
}

output "backup_vol_ids" { value = local.Backup_ids }
output "appdbsrv_ids" { value = local.Fn4AppDb_ids }

