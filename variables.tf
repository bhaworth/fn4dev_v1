variable "tenancy_ocid" {}
variable "region" {}
variable "compartment_ocid" {}
variable "ssh_pub_key" {}
variable "bastion_shape" {}
variable "bastion_image" {}
variable "bastion_ocpus" { default = 1 }
variable "bastion_ram" { default = 16 }
variable "appdbsrv_shape" {}
variable "appdbsrv_image" {}
variable "appdbsrv_ocpus" { default = 1 }
variable "appdbsrv_ram" { default = 16 }
variable "appdbsrv_count" { default = 1 }
variable "bastion_boot_size" { default = 50 }
variable "appdb_boot_size" { default = 120 }
variable "appdb_backup_size" { default = 500 }
variable "randomise_ad" { default = true }
variable "ad" { default = "" }
variable "name_prefix" { default = "" }
variable "env_name" { default = "fn4" }
variable "deploy_test" { default = false }
variable "show_testing_others" { default = false }
variable "specify_prefix" { default = false }
variable "create_child_comp" { default = true }
variable "install_certs" { default = true }
variable "create_dns" { default = true }
variable "custom_worker_img" { default = "" }
variable "select_cust_worker_img" { default = false }

locals {
  compute_flexible_shapes  = ["VM.Standard.E3.Flex"]
  Fn4_deploy_id            = random_string.deploy_id.result
  Fn4_gitrepo_secret_id    = ""
  Fn4dev_ml_ssl_secret_id  = ""
  Fn4dev_ml_priv_secret_id = ""
  Fn4dev_ml_dns_zone_id    = "ocid1.dns-zone.oc1..3ec42db37b15485f877bc7aaa5efd291"
  Fn4dev_comp_id           = "ocid1.compartment.oc1..aaaaaaaapxuxy4xbpyrx5w5z26zs7eebjmxbrnsqlawbf7fwe3voddtkygfq"
}
