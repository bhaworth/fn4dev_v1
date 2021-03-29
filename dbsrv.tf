locals {
  Fn4_dbsrv_shape         = var.dbsrv_shape
  Fn4_dbsrv_image         = var.dbsrv_image
  is_flexible_dbsrv_shape = contains(local.compute_flexible_shapes, local.Fn4_dbsrv_shape)
}



# ------ Create DB Srv Instance
resource "oci_core_instance" "Fn4Db" {
  count = var.dbsrv_count
  # Required
  compartment_id = local.Fn4_cid
  shape          = local.Fn4_dbsrv_shape
  # Optional
  display_name = "${local.Fn4_env_name}-db-${count.index + 1}"


  # If count < 3 then fn4_ad else choose another based on calculation based on count

  availability_domain = [count.index < 2] ? local.Fn4_ad : local.ad_random_seq[count.index % length(local.ad_random_seq)]

  # Set fault domain to be a calculation from count

  fault_domain = "FAULT-DOMAIN-${count.index + 1}"

  create_vnic_details {
    # Required
    subnet_id = local.Privsn001_id
    # Optional
    assign_public_ip       = false
    display_name           = "${local.Fn4_env_name}-db-${count.index + 1} vnic 00"
    hostname_label         = "${local.Fn4_env_name}-db-${count.index + 1}"
    skip_source_dest_check = "false"
    nsg_ids                = [local.db_nsg_id]
  }
  metadata = {
    ssh_authorized_keys = local.Fn4_ssh_key
    user_data           = data.template_cloudinit_config.dbsrv.rendered
  }

  dynamic "shape_config" {
    for_each = local.is_flexible_dbsrv_shape ? [1] : []
    content {
      ocpus         = var.dbsrv_ocpus
      memory_in_gbs = var.dbsrv_ram
    }
  }
  source_details {
    # Required
    source_id   = local.Fn4_dbsrv_image
    source_type = "image"
    # Optional
    boot_volume_size_in_gbs = var.dbsrv_boot_size
    #        kms_key_id              = 
  }
  preserve_boot_volume = false
}

locals {
  Fn4Db_ids         = oci_core_instance.Fn4Db.*.id
  Fn4Db_private_ips = oci_core_instance.Fn4Db.*.private_ip
}

output "Fn4Db_SrvPrivateIP" {
  value = local.Fn4Db_private_ips
}

output "dbsrv_ids" { value = local.Fn4Db_ids }

# ------ Create Block Storage Volume
resource "oci_core_volume" "BackupClone" {
  count = var.clone_db_backup ? 1 : 0
  # Required
  compartment_id = local.Fn4_cid

  # Only one backup attachment so use base AD
  availability_domain = local.Fn4_ad

  # Optional
  display_name = "${local.Fn4_env_name}-db-backup"

  source_details {
    type = volume
    id   = var.dbsrv_src_backup_vol_id
  }

}

locals {
  BackupVol_id = oci_core_volume.BackupClone.id
}

# ------ Create Block Storage Attachments
resource "oci_core_volume_attachment" "BackupCloneVolumeAttachment" {
  count                               = var.clone_db_backup ? 1 : 0
  attachment_type                     = "paravirtualized"
  device                              = "/dev/oracleoci/oraclevdb"
  display_name                        = "${local.Fn4_env_name}-BackupCloneVolumeAttachment"
  instance_id                         = oci_core_instance.Fn4AppDb[0].id
  is_pv_encryption_in_transit_enabled = "false"
  is_read_only                        = "false"
  #is_shareable = <<Optional value not found in discovery>>
  #use_chap = <<Optional value not found in discovery>>
  volume_id = local.BackupVol_id
}
