variable "tenancy_ocid" {}
variable "region" {}
variable "compartment_ocid" {}
variable "ssh_pub_key" {}
variable "bastion_shape" {}
variable "bastion_image" {}
variable "bastion_ocpus" { default = 1 }
variable "bastion_ram" { default = 16 }
variable "appsrv_shape" {}
variable "appsrv_image" {}
variable "appsrv_ocpus" { default = 1 }
variable "appsrv_ram" { default = 16 }
variable "appsrv_count" { default = 1 }
variable "appsrv_boot_size" { default = 120 }
variable "dbsrv_shape" {}
variable "dbsrv_image" {}
variable "dbsrv_ocpus" { default = 1 }
variable "dbsrv_ram" { default = 16 }
variable "dbsrv_count" { default = 1 }
variable "dbsrv_boot_size" { default = 120 }
variable "clone_db_backup" { default = true }
variable "dbsrv_src_backup_vol_id" { default = "" }
variable "bastion_boot_size" { default = 50 }
# variable "randomise_ad" { default = true }
# variable "ad" { default = "" }
variable "name_prefix" { default = "" }
variable "env_name" { default = "fn4" }
variable "deploy_test" { default = false }
variable "show_testing_others" { default = false }
variable "specify_prefix" { default = false }
variable "create_child_comp" { default = true }
# variable "install_certs" { default = true }
variable "create_dns" { default = true }

locals {
  compute_flexible_shapes  = ["VM.Standard.E3.Flex"]
  Fn4_deploy_id            = random_string.deploy_id.result
  Fn4_gitrepo_secret_id    = ""
  Fn4dev_ml_ssl_secret_id  = ""
  Fn4dev_ml_priv_secret_id = ""
  Fn4dev_ml_dns_zone_id    = "ocid1.dns-zone.oc1..3ec42db37b15485f877bc7aaa5efd291"
  Fn4dev_comp_id           = "ocid1.compartment.oc1..aaaaaaaapxuxy4xbpyrx5w5z26zs7eebjmxbrnsqlawbf7fwe3voddtkygfq"
}
